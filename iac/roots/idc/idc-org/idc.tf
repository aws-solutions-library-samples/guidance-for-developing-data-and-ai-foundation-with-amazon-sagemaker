// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_ssoadmin_instances" "identity_center" {}

data "aws_organizations_organization" "org" {}

data "aws_kms_key" "ssm_kms_key" {

  key_id   = "alias/${var.SSM_KMS_KEY_ALIAS}"
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = var.LAMBDA_BUCKET
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

resource "aws_identitystore_group" "groups" {

  for_each          = toset(var.GROUPS)
  identity_store_id = data.aws_ssoadmin_instances.identity_center.identity_store_ids[0]
  display_name      = each.value
}

resource "aws_identitystore_user" "users" {

  for_each          = var.USERS
  identity_store_id = data.aws_ssoadmin_instances.identity_center.identity_store_ids[0]
  user_name         = each.value.email
  display_name      = each.key
  name {
    given_name      = each.value.given_name
    family_name     = each.value.family_name
  }
  emails {
    value           = each.value.email
    primary         = true
  }
}

resource "aws_identitystore_group_membership" "user_group_membership" {

  for_each = { for user, details in var.USERS : user => details.groups }
  identity_store_id = data.aws_ssoadmin_instances.identity_center.identity_store_ids[0]
  group_id          = aws_identitystore_group.groups[each.value[0]].group_id
  member_id         = aws_identitystore_user.users[each.key].user_id
}

resource "aws_ssoadmin_permission_set" "permissions" {

  for_each         = var.PERMISSION_SETS
  instance_arn     = data.aws_ssoadmin_instances.identity_center.arns[0]
  name             = each.value.name
  description      = each.value.description
  session_duration = each.value.session_duration
}

resource "aws_ssoadmin_account_assignment" "identity_assignments" {

  for_each            = toset(data.aws_organizations_organization.org.accounts[*].id)
  instance_arn        = data.aws_ssoadmin_instances.identity_center.arns[0]
  permission_set_arn  = aws_ssoadmin_permission_set.permissions["Admin"].arn
  principal_type      = "GROUP"
  principal_id        = aws_identitystore_group.groups["Admin"].group_id
  target_type         = "AWS_ACCOUNT"
  target_id           = each.value
}

resource "aws_iam_policy" "project_owner_policy" {

  name = "SageMakerStudioProjectOwnerPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "datazone:CreateProjectMembership",
          "datazone:DeleteProjectMembership",
          "datazone:ListProjectMemberships",
          "datazone:GetProject",
          "datazone:UpdateProject",
          "datazone:ListProjects"
        ]
        Resource = [
          "arn:aws:datazone:${local.region}:${local.account_id}:domain/*"
        ]      }
    ]
  })
}

resource "aws_iam_policy" "domain_owner_policy" {

  name = "SageMakerStudioDomainOwnerPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "datazone:GetUserProfile",
          "datazone:CreateUserProfile",
          "datazone:DeleteUserProfile",
          "datazone:UpdateUserProfile"
        ]
        Resource = [
          "arn:aws:datazone:${local.region}:${local.account_id}:domain/*"
        ]      }
    ]
  })
}

resource "aws_iam_policy" "project_contributor_policy" {

  name = "SageMakerStudioProjectMemberPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "datazone:CreateDataSource",
          "datazone:UpdateDataSource",
          "datazone:DeleteDataSource",
          "datazone:GetDataSource",
          "datazone:ListDataSources",
          "datazone:CreateAsset",
          "datazone:UpdateAsset",
          "datazone:DeleteAsset",
          "datazone:GetAsset",
          "datazone:CreateDataProduct",
          "datazone:UpdateDataProduct",
          "datazone:DeleteDataProduct",
          "datazone:GetDataProduct",
          "datazone:CreateSubscriptionRequest",
          "datazone:UpdateSubscriptionRequest",
          "datazone:DeleteSubscriptionRequest",
          "datazone:GetSubscriptionRequestDetails",
          "datazone:ListSubscriptionRequests",
          "datazone:StartDataSourceRun",
          "datazone:GetDataSourceRun",
          "datazone:ListDataSourceRuns",
          "datazone:GetLineageNode",
          "datazone:ListLineageNodeHistory",
          "datazone:Search",
          "datazone:SearchListings"
        ]
        Resource = [
          "arn:aws:datazone:${local.region}:${local.account_id}:domain/*"
        ]
      },
      {
        Sid = "AllowDataToolsAccess",
        Effect = "Allow",
        Action = [
          "glue:StartCompletion",
          "glue:GetCompletion",
          "athena:StartQueryExecution",
          "athena:GetQueryExecution"
        ],
        Resource = [
          "arn:aws:datazone:${local.region}:${local.account_id}:domain/*"
        ]      }
    ]
  })
}

resource "aws_ssoadmin_managed_policy_attachment" "policy_attachments" {

  for_each          = {
    for item in flatten([
      for perm_set, details in var.PERMISSION_SETS : [
        for policy in details.policies : {
          key                 = "${perm_set}-${policy}"
          permission_set_arn  = aws_ssoadmin_permission_set.permissions[perm_set].arn
          policy              = policy
        }
      ]
    ]) : item.key => item
  }

  instance_arn       = data.aws_ssoadmin_instances.identity_center.arns[0]
  permission_set_arn = each.value.permission_set_arn
  managed_policy_arn = each.value.policy

  depends_on         = [aws_ssoadmin_account_assignment.identity_assignments]
}

resource "aws_ssoadmin_customer_managed_policy_attachment" "domain_owner_attachment" {

  instance_arn       = tolist(data.aws_ssoadmin_instances.identity_center.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.permissions["Domain Owner"].arn
  customer_managed_policy_reference {
    name = aws_iam_policy.domain_owner_policy.name
  }
}

resource "aws_ssoadmin_customer_managed_policy_attachment" "project_owner_attachment" {

  instance_arn       = tolist(data.aws_ssoadmin_instances.identity_center.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.permissions["Project Owner"].arn
  customer_managed_policy_reference {
    name = aws_iam_policy.project_owner_policy.name
  }
}

resource "aws_ssoadmin_customer_managed_policy_attachment" "project_member_attachment" {

  instance_arn       = tolist(data.aws_ssoadmin_instances.identity_center.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.permissions["Project Contributor"].arn
  customer_managed_policy_reference {
    name = aws_iam_policy.project_contributor_policy.name
  }
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
}
