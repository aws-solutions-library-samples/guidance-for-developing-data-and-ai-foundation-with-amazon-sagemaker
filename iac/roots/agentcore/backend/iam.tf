// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# ---------------------------------------------------------------------------
# AgentCore Lambda execution role (shared across all 3 Lambda functions)
# ---------------------------------------------------------------------------

resource "aws_iam_role" "agentcore_lambda_role" {
  name = "${var.APP}-${var.ENV}-agentcore-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "agentcore-lambda"
  }
}

# Athena query permissions
resource "aws_iam_role_policy" "lambda_athena" {
  name = "athena-query"
  role = aws_iam_role.agentcore_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "athena:StartQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "athena:ListDatabases",
          "athena:ListTableMetadata"
        ]
        Resource = [
          "arn:aws:athena:${data.aws_region.current.id}:${local.account_id}:workgroup/${local.athena_workgroup}",
          "arn:aws:athena:${data.aws_region.current.id}:${local.account_id}:datacatalog/AwsDataCatalog"
        ]
      }
    ]
  })
}

# Glue catalog permissions
resource "aws_iam_role_policy" "lambda_glue" {
  name = "glue-catalog"
  role = aws_iam_role.agentcore_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetPartitions"
        ]
        Resource = [
          "arn:aws:glue:${data.aws_region.current.id}:${local.account_id}:catalog",
          "arn:aws:glue:${data.aws_region.current.id}:${local.account_id}:database/*",
          "arn:aws:glue:${data.aws_region.current.id}:${local.account_id}:table/*"
        ]
      }
    ]
  })
}

# S3 permissions for Athena query results. Data lake tables are read through
# Lake Formation, which vends its own temporary credentials for the registered
# locations, so the role needs no direct access to the data lake buckets.
resource "aws_iam_role_policy" "lambda_s3" {
  name = "s3-access"
  role = aws_iam_role.agentcore_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${local.athena_output_bucket}",
          "arn:aws:s3:::${local.athena_output_bucket}/*"
        ]
      }
    ]
  })
}

# KMS permissions
resource "aws_iam_role_policy" "lambda_kms" {
  name = "kms-access"
  role = aws_iam_role.agentcore_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = ["*"]
        Condition = {
          StringEquals = {
            "kms:CallerAccount" = local.account_id
          }
        }
      }
    ]
  })
}

# CloudWatch Logs permissions
resource "aws_iam_role_policy" "lambda_logs" {
  name = "cloudwatch-logs"
  role = aws_iam_role.agentcore_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.id}:${local.account_id}:*"
      }
    ]
  })
}

# Lake Formation data access
resource "aws_iam_role_policy" "lambda_lakeformation" {
  name = "lakeformation-access"
  role = aws_iam_role.agentcore_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["lakeformation:GetDataAccess"]
        Resource = ["*"]
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# Agent Core role (gateway assumes this to invoke Lambda)
# ---------------------------------------------------------------------------

resource "aws_iam_role" "agent_core_role" {
  name = "${var.APP}-${var.ENV}-agent-core-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "bedrock-agentcore.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "agentcore-gateway"
  }
}

resource "aws_iam_role_policy" "agent_core_lambda_invoke" {
  name = "lambda-invoke"
  role = aws_iam_role.agent_core_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["lambda:InvokeFunction"]
        Resource = [
          aws_lambda_function.get_databases.arn,
          aws_lambda_function.get_database_tables.arn,
          aws_lambda_function.execute_query.arn,
          aws_lambda_function.web_search.arn
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = [aws_iam_role.agent_core_role.arn]
      }
    ]
  })
}
