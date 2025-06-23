// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

resource "aws_kms_key" "sm_primary_key" {

  provider            = aws.primary

  enable_key_rotation = true
  description         = "${var.APP}-${var.ENV}-secrets-manager-secret-key"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${local.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
POLICY

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "secrets manager"
    Name        = "${var.APP}-${var.ENV}-secrets-manager-secret-key"
  }
}

resource "aws_kms_alias" "sm_primary_key_alias" {

  provider      = aws.primary

  name          = "alias/${var.APP}-${var.ENV}-secrets-manager-secret-key"
  target_key_id = aws_kms_key.sm_primary_key.key_id
}

resource "aws_kms_key" "sm_secondary_key" {

  provider            = aws.secondary

  enable_key_rotation = true
  description         = "${var.APP}-${var.ENV}-secrets-manager-secret-key"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${local.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
POLICY

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "secrets manager"
    Name        = "${var.APP}-${var.ENV}-secrets-manager-secret-key"
  }
}

resource "aws_kms_alias" "sm_secondary_key_alias" {

  provider      = aws.secondary

  name          = "alias/${var.APP}-${var.ENV}-secrets-manager-secret-key"
  target_key_id = aws_kms_key.sm_secondary_key.key_id
}

// Systems Manager
resource "aws_kms_key" "ssm_primary_key" {

  provider            = aws.primary

  enable_key_rotation = true
  description         = "${var.APP}-${var.ENV}-systems-manager-secret-key"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${local.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
POLICY

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "systems manager"
    Name        = "${var.APP}-${var.ENV}-systems-manager-secret-key"
  }
}

resource "aws_kms_alias" "ssm_primary_key_alias" {

  provider      = aws.primary

  name          = "alias/${var.APP}-${var.ENV}-systems-manager-secret-key"
  target_key_id = aws_kms_key.ssm_primary_key.key_id
}

resource "aws_kms_key" "ssm_secondary_key" {

  provider            = aws.secondary

  enable_key_rotation = true
  description         = "${var.APP}-${var.ENV}-systems-manager-secret-key"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${local.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
POLICY

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "systems manager"
    Name        = "${var.APP}-${var.ENV}-systems-manager-secret-key"
  }
}

resource "aws_kms_alias" "ssm_secondary_key_alias" {

  provider      = aws.secondary

  name          = "alias/${var.APP}-${var.ENV}-systems-manager-secret-key"
  target_key_id = aws_kms_key.ssm_secondary_key.key_id
}

// S3
resource "aws_kms_key" "s3_primary_key" {

  provider            = aws.primary

  enable_key_rotation = true
  description         = "${var.APP}-${var.ENV}-s3-secret-key"

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "s3"
    Name        = "${var.APP}-${var.ENV}-s3-secret-key"
  }

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "key-s3-policy-1",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${local.account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Allow Amazon S3 use of the KMS key",
            "Effect": "Allow",
            "Principal": {
                "Service": "s3.amazonaws.com"
            },
            "Action": [
                "kms:GenerateDataKey*",
                "kms:Decrypt*"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:SourceAccount": "${local.account_id}"
                },
                "ArnLike": {
                    "aws:SourceArn": "arn:aws:s3:::*"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_kms_alias" "s3_primary_key_alias" {

  provider      = aws.primary

  name          = "alias/${var.APP}-${var.ENV}-s3-secret-key"
  target_key_id = aws_kms_key.s3_primary_key.key_id
}

resource "aws_kms_key" "s3_secondary_key" {

  provider            = aws.secondary

  enable_key_rotation = true
  description         = "${var.APP}-${var.ENV}-s3-secret-key"

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "s3"
    Name        = "${var.APP}-${var.ENV}-s3-secret-key"
  }

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "key-s3-policy-2",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${local.account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Allow Amazon S3 use of the KMS key",
            "Effect": "Allow",
            "Principal": {
                "Service": "s3.amazonaws.com"
            },
            "Action": [
                "kms:GenerateDataKey*",
                "kms:Decrypt*"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:SourceAccount": "${local.account_id}"
                },
                "ArnLike": {
                    "aws:SourceArn": "arn:aws:s3:::*"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_kms_alias" "s3_secondary_key_alias" {

  provider      = aws.secondary

  name          = "alias/${var.APP}-${var.ENV}-s3-secret-key"
  target_key_id = aws_kms_key.s3_secondary_key.key_id
}

// Glue
resource "aws_kms_key" "glue_primary_key" {

  provider            = aws.primary

  enable_key_rotation = true
  description         = "${var.APP}-${var.ENV}-glue-secret-key"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${local.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "glue.amazonaws.com"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
POLICY

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "glue"
    Name        = "${var.APP}-${var.ENV}-glue-secret-key"
  }
}

resource "aws_kms_alias" "glue_primary_key_alias" {

  provider      = aws.primary

  name          = "alias/${var.APP}-${var.ENV}-glue-secret-key"
  target_key_id = aws_kms_key.glue_primary_key.key_id
}

resource "aws_kms_key" "glue_secondary_key" {

  provider            = aws.secondary

  enable_key_rotation = true
  description         = "${var.APP}-${var.ENV}-glue-secret-key"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${local.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
POLICY

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "glue"
    Name        = "${var.APP}-${var.ENV}-glue-secret-key"
  }
}

resource "aws_kms_alias" "glue_secondary_key_alias" {

  provider      = aws.secondary

  name          = "alias/${var.APP}-${var.ENV}-glue-secret-key"
  target_key_id = aws_kms_key.glue_secondary_key.key_id
}

// Athena
resource "aws_kms_key" "athena_primary_key" {

  provider            = aws.primary

  enable_key_rotation = true
  description         = "${var.APP}-${var.ENV}-athena-secret-key"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${local.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
POLICY

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "athena"
    Name        = "${var.APP}-${var.ENV}-athena-secret-key"
  }
}

resource "aws_kms_alias" "athena_primary_key_alias" {

  provider      = aws.primary

  name          = "alias/${var.APP}-${var.ENV}-athena-secret-key"
  target_key_id = aws_kms_key.athena_primary_key.key_id
}

resource "aws_kms_key" "athena_secondary_key" {

  provider            = aws.secondary

  enable_key_rotation = true
  description         = "${var.APP}-${var.ENV}-athena-secret-key"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${local.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
POLICY

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "athena"
    Name        = "${var.APP}-${var.ENV}-athena-secret-key"
  }
}

resource "aws_kms_alias" "athena_secondary_key_alias" {

  provider      = aws.secondary

  name          = "alias/${var.APP}-${var.ENV}-athena-secret-key"
  target_key_id = aws_kms_key.athena_secondary_key.key_id
}

// Event Bridge
resource "aws_kms_key" "event_bridge_primary_key" {

  provider            = aws.primary

  enable_key_rotation = true
  description         = "${var.APP}-${var.ENV}-event-bridge-secret-key"
  
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${local.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
POLICY

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "event bridge"
    Name        = "${var.APP}-${var.ENV}-event-bridge-secret-key"
  }
}

resource "aws_kms_alias" "event_bridge" {

  provider      = aws.primary

  name          = "alias/${var.APP}-${var.ENV}-event-bridge-secret-key"
  target_key_id = aws_kms_key.event_bridge_primary_key.key_id
}

resource "aws_kms_key" "event_bridge_secondary_key" {

  provider            = aws.secondary

  enable_key_rotation = true
  description         = "${var.APP}-${var.ENV}-event-bridge-secret-key"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${local.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
POLICY

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "event bridge"
    Name        = "${var.APP}-${var.ENV}-event-bridge-secret-key"
  }
}

resource "aws_kms_alias" "event_bridge_secondary_key_alias" {

  provider      = aws.secondary

  name          = "alias/${var.APP}-${var.ENV}-event-bridge-secret-key"
  target_key_id = aws_kms_key.event_bridge_secondary_key.key_id
}

// Cloudwatch
resource "aws_kms_key" "cloudwatch_primary_key" {

  provider            = aws.primary

  enable_key_rotation = true
  description         = "${var.APP}-${var.ENV}-cloudwatch-secret-key"
  
  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "cloud watch"
    Name        = "${var.APP}-${var.ENV}-cloudwatch-secret-key"
  }

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "key-default-1",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${local.account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "logs.${var.AWS_PRIMARY_REGION}.amazonaws.com"
            },
            "Action": [
                "kms:Encrypt*",
                "kms:Decrypt*",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:Describe*"
            ],
            "Resource": "*",
            "Condition": {
                "ArnLike": {
                    "kms:EncryptionContext:aws:logs:arn": "arn:aws:logs:${var.AWS_PRIMARY_REGION}:${local.account_id}:*"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_kms_alias" "cloudwatch_primary_key_alias" {

  provider      = aws.primary

  name          = "alias/${var.APP}-${var.ENV}-cloudwatch-secret-key"
  target_key_id = aws_kms_key.cloudwatch_primary_key.key_id
}

resource "aws_kms_key" "cloudwatch_secondary_key" {

  provider            = aws.secondary

  enable_key_rotation = true
  description         = "${var.APP}-${var.ENV}-cloudwatch-secret-key"
  
  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "cloud watch"
    Name        = "${var.APP}-${var.ENV}-cloudwatch-secret-key"
  }

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "key-default-1",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${local.account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "logs.${var.AWS_SECONDARY_REGION}.amazonaws.com"
            },
            "Action": [
                "kms:Encrypt*",
                "kms:Decrypt*",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:Describe*"
            ],
            "Resource": "*",
            "Condition": {
                "ArnLike": {
                    "kms:EncryptionContext:aws:logs:arn": "arn:aws:logs:${var.AWS_SECONDARY_REGION}:${local.account_id}:*"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_kms_alias" "cloudwatch_secondary_key_alias" {

  provider      = aws.secondary

  name          = "alias/${var.APP}-${var.ENV}-cloudwatch-secret-key"
  target_key_id = aws_kms_key.cloudwatch_secondary_key.key_id
}

// Datazone
resource "aws_kms_key" "dz_primary_key" {

  provider            = aws.primary

  enable_key_rotation = true
  description         = "${var.APP}-${var.ENV}-datazone-secret-key"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${local.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
POLICY

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "datazone"
    Name        = "${var.APP}-${var.ENV}-datazone-secret-key"
  }
}

resource "aws_kms_alias" "dz_primary_key_alias" {

  provider      = aws.primary

  name          = "alias/${var.APP}-${var.ENV}-datazone-secret-key"
  target_key_id = aws_kms_key.dz_primary_key.key_id
}

resource "aws_kms_key" "dz_secondary_key" {

  provider            = aws.secondary

  enable_key_rotation = true
  description         = "${var.APP}-${var.ENV}-datazone-secret-key"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${local.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
POLICY

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "datazaone"
    Name        = "${var.APP}-${var.ENV}-datazone-secret-key"
  }
}

resource "aws_kms_alias" "dz_secondary_key_alias" {

  provider      = aws.secondary

  name          = "alias/${var.APP}-${var.ENV}-datazone-secret-key"
  target_key_id = aws_kms_key.dz_secondary_key.key_id
}

// EBS
resource "aws_kms_key" "ebs_primary_key" {

  provider            = aws.primary

  enable_key_rotation = true
  description         = "${var.APP}-${var.ENV}-ebs-secret-key"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${local.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
POLICY

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "EBS"
    Name        = "${var.APP}-${var.ENV}-ebs-secret-key"
  }
}

resource "aws_kms_alias" "ebs_primary_key_alias" {

  provider      = aws.primary

  name          = "alias/${var.APP}-${var.ENV}-ebs-secret-key"
  target_key_id = aws_kms_key.ebs_primary_key.key_id
}

resource "aws_kms_key" "ebs_secondary_key" {

  provider            = aws.secondary

  enable_key_rotation = true
  description         = "${var.APP}-${var.ENV}-ebs-secret-key"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${local.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
POLICY

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "EBS"
    Name        = "${var.APP}-${var.ENV}-ebs-secret-key"
  }
}

resource "aws_kms_alias" "ebs_secondary_key_alias" {

  provider      = aws.secondary

  name          = "alias/${var.APP}-${var.ENV}-ebs-secret-key"
  target_key_id = aws_kms_key.ebs_secondary_key.key_id
}

// Dynamodb

resource "aws_kms_key" "dynamodb_primary_key" {

  provider            = aws.primary

  enable_key_rotation = true
  description         = "${var.APP}-${var.ENV}-dynamodb-secret-key"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${local.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Enable Glue to Decrypt key",
      "Effect": "Allow",
      "Principal": {
        "Service": "glue.amazonaws.com"
      },
      "Action": "kms:Decrypt",
      "Resource": "*"
    }
  ]
}
POLICY

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "dynamodb"
    Name        = "${var.APP}-${var.ENV}-dynamodb-secret-key"
  }
}

resource "aws_kms_alias" "dynamodb_primary_key_alias" {

  provider      = aws.primary

  name          = "alias/${var.APP}-${var.ENV}-dynamodb-secret-key"
  target_key_id = aws_kms_key.dynamodb_primary_key.id
}

resource "aws_kms_key" "msk_primary_key" {

  provider            = aws.primary

  enable_key_rotation = true
  description         = "${var.APP}-${var.ENV}-msk-secret-key"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${local.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
POLICY

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "msk"
    Name        = "${var.APP}-${var.ENV}-msk-secret-key"
  }
}

resource "aws_kms_alias" "msk_primary_key_alias" {

  provider      = aws.primary

  name          = "alias/${var.APP}-${var.ENV}-msk-secret-key"
  target_key_id = aws_kms_key.msk_primary_key.key_id
}

resource "aws_kms_key" "msk_secondary_key" {

  provider            = aws.secondary

  enable_key_rotation = true
  description         = "${var.APP}-${var.ENV}-msk-secret-key"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${local.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
POLICY

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "msk"
    Name        = "${var.APP}-${var.ENV}-msk-secret-key"
  }
}

resource "aws_kms_alias" "msk_secondary_key_alias" {

  provider      = aws.secondary

  name          = "alias/${var.APP}-${var.ENV}-msk-secret-key"
  target_key_id = aws_kms_key.msk_secondary_key.key_id
}