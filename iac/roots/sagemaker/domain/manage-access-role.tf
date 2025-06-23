// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

resource "aws_iam_role" "smus_domain_manage_access_role" {

  name = "AmazonSageMakerManageAccess-${local.region}-${local.domain_id}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "datazone.amazonaws.com"
        }
        Condition = {
          "StringEquals" : {
            "aws:SourceAccount" : local.account_id
          },
          "ArnEquals" : {
            "aws:SourceArn" : "arn:aws:datazone:${local.region}:${local.account_id}:domain/${local.domain_id}"
          }
        }
      }
    ]
  })
}

# Attach inline policy to the role, allowing secretsmanager:GetSecretValue
resource "aws_iam_role_policy" "smus_domain_manage_access_role_policy" {

  name = "smus-manage-access-role-policy"
  role = aws_iam_role.smus_domain_manage_access_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "secretsmanager:ResourceTag/AmazonDataZoneDomain" : "${local.domain_id}"
          }
        }
      }
    ]
  })
}

# Attach other AWS managed policies that the Console created role has
resource "aws_iam_role_policy_attachment" "smus_domain_manage_access_role_policy_attachments" {

  for_each = toset([
    "arn:aws:iam::aws:policy/service-role/AmazonDataZoneGlueManageAccessRolePolicy",
    "arn:aws:iam::aws:policy/service-role/AmazonDataZoneRedshiftManageAccessRolePolicy",
    "arn:aws:iam::aws:policy/AmazonDataZoneSageMakerManageAccessRolePolicy"
  ])
  role       = aws_iam_role.smus_domain_manage_access_role.name
  policy_arn = each.value
}

# update KMS key policy data.aws_kms_key.domain_kms_key to grant kms:* permissions on this role as the principal
resource "aws_kms_key_policy" "smus_domain_manage_access_role_kms_policy" {

  key_id = data.aws_kms_key.domain_kms_key.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.smus_domain_manage_access_role.arn
        }
        Action   = "kms:*"
        Resource = "*"
      },
      # {
      #   Sid    = "Allow access for SageMaker Lakehouse Federated Query"
      #   Effect = "Allow"
      #   Principal = {
      #     AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/SageMakerStudioQueryExecutionRole"
      #   }
      #   Action   = "kms:*"
      #   Resource = "*"
      # },
      {
        Sid    = "TO BE SCOPED DOWN - Allow access for SageMaker Lakehouse Federated Query"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}
