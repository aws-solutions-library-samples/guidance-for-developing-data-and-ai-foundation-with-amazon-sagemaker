// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_kms_key" "ssm_kms_key" {

  key_id = "alias/${var.SSM_KMS_KEY_ALIAS}"
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = var.LAMBDA_BUCKET
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/instance_creation.py"
  output_path = "${path.module}/instance_creation.zip"
}

resource "aws_s3_object" "lambda_zip" {
  bucket = aws_s3_bucket.lambda_bucket.id  # Reference the bucket resource
  key    = var.LAMBDA_KEY
  source = data.archive_file.lambda_zip.output_path
  etag   = filemd5(data.archive_file.lambda_zip.output_path)
}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.APP}-${var.ENV}-lambda-idc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "basic_lambda" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_permissions" {
  name = "${var.APP}-${var.ENV}-idc-lambda-permissions"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sso:*",
          "identitystore:*",
          "iam:CreateServiceLinkedRole",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = "iam:CreateServiceLinkedRole",
        Resource = "arn:aws:iam::*:role/aws-service-role/sso.amazonaws.com/AWSServiceRoleForSSO",
        Condition = {
          StringLike = {
            "iam:AWSServiceName" = "sso.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_lambda_function" "idc_creator" {
  function_name = "${var.APP}-${var.ENV}-idc-instance-creator"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "instance_creation.lambda_handler"
  runtime       = "python3.9"
  timeout       = 60

  s3_bucket = var.LAMBDA_BUCKET
  s3_key    = var.LAMBDA_KEY

  depends_on = [aws_s3_object.lambda_zip]
}

resource "null_resource" "invoke_lambda" {
  depends_on = [aws_lambda_function.idc_creator]

  provisioner "local-exec" {
    command = <<EOT
      aws lambda invoke \
        --function-name ${aws_lambda_function.idc_creator.function_name} \
        --payload '{"RequestType": "Create"}' \
        --invocation-type RequestResponse \
        --cli-binary-format raw-in-base64-out \
        --region ${var.AWS_PRIMARY_REGION} \
        response.json
    EOT
  }

  triggers = {
    always_run = timestamp()
  }
}

data "aws_ssoadmin_instances" "identity_center" {
  depends_on = [null_resource.invoke_lambda]
}


resource "aws_identitystore_group" "groups" {

  for_each          = toset(var.GROUPS)
  identity_store_id = data.aws_ssoadmin_instances.identity_center.identity_store_ids[0]
  display_name      = each.value
  depends_on        = [null_resource.invoke_lambda]
}

resource "aws_identitystore_user" "users" {

  for_each          = var.USERS
  identity_store_id = data.aws_ssoadmin_instances.identity_center.identity_store_ids[0]
  user_name         = each.value.email
  display_name      = each.key
  name {
    given_name  = each.value.given_name
    family_name = each.value.family_name
  }
  emails {
    value   = each.value.email
    primary = true
  }
  depends_on        = [null_resource.invoke_lambda]
}

resource "aws_identitystore_group_membership" "user_group_membership" {

  for_each          = { for user, details in var.USERS : user => details.groups }
  identity_store_id = data.aws_ssoadmin_instances.identity_center.identity_store_ids[0]
  group_id          = aws_identitystore_group.groups[each.value[0]].group_id
  member_id         = aws_identitystore_user.users[each.key].user_id
  depends_on        = [aws_identitystore_user.users]
}

resource "aws_iam_role" "identity_role" {

  for_each = {
    for k, v in var.PERMISSION_SETS : k => v
    if k != var.ADMIN_ROLE
  }

  name = replace(each.key, " ", "-")

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "datazone.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "role_policy_attachment" {

  for_each   = var.PERMISSION_SETS
  role       = replace(each.key, " ", "-")
  policy_arn = each.value.policies[0]

  depends_on = [aws_iam_role.identity_role]
}

locals {
  group_memberships = {
    for group in aws_identitystore_group.groups :
    group.display_name => flatten([
      for membership in aws_identitystore_group_membership.user_group_membership :
      [
        for user in aws_identitystore_user.users :
        user.user_name
        if user.user_id == membership.member_id
      ]
      if membership.group_id == group.group_id
    ])
  }

  user_group_mappings = {
    (data.aws_ssoadmin_instances.identity_center.identity_store_ids[0]) = local.group_memberships
  }
}

# Save the users (group, name and uid) info in SSM Parameter Store
resource "aws_ssm_parameter" "identity_center_users" {
  name        = "/${var.APP}/${var.ENV}/identity-center/users"
  description = "Map of IAM Identity Center users and their group associations"
  type        = "SecureString"
  value       = jsonencode(local.user_group_mappings)
  key_id      = data.aws_kms_key.ssm_kms_key.id

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "Identity Center Users and Groups Mapping"
  }
  depends_on = [aws_iam_role.identity_role]
}
