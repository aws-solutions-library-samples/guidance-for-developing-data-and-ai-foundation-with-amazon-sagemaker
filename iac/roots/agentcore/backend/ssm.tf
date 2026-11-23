// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# ---------------------------------------------------------------------------
# SSM Parameters — interface contract for the gateway workstream
# ---------------------------------------------------------------------------

resource "aws_ssm_parameter" "cognito_user_pool_id" {
  name      = "/${var.APP}/${var.ENV}/agentcore/cognito-user-pool-id"
  type      = "SecureString"
  value     = aws_cognito_user_pool.agentcore.id
  key_id    = data.aws_kms_key.ssm_key.arn
  overwrite = true

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "agentcore"
  }
}

resource "aws_ssm_parameter" "cognito_app_client_id" {
  name      = "/${var.APP}/${var.ENV}/agentcore/cognito-app-client-id"
  type      = "SecureString"
  value     = aws_cognito_user_pool_client.agentcore.id
  key_id    = data.aws_kms_key.ssm_key.arn
  overwrite = true

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "agentcore"
  }
}

resource "aws_ssm_parameter" "cognito_endpoint" {
  name      = "/${var.APP}/${var.ENV}/agentcore/cognito-endpoint"
  type      = "SecureString"
  value     = "https://${aws_cognito_user_pool_domain.agentcore.domain}.auth.${data.aws_region.current.id}.amazoncognito.com"
  key_id    = data.aws_kms_key.ssm_key.arn
  overwrite = true

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "agentcore"
  }
}

resource "aws_ssm_parameter" "lambda_get_databases_arn" {
  name      = "/${var.APP}/${var.ENV}/agentcore/lambda-get-databases-arn"
  type      = "SecureString"
  value     = aws_lambda_function.get_databases.arn
  key_id    = data.aws_kms_key.ssm_key.arn
  overwrite = true

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "agentcore"
  }
}

resource "aws_ssm_parameter" "lambda_get_database_tables_arn" {
  name      = "/${var.APP}/${var.ENV}/agentcore/lambda-get-database-tables-arn"
  type      = "SecureString"
  value     = aws_lambda_function.get_database_tables.arn
  key_id    = data.aws_kms_key.ssm_key.arn
  overwrite = true

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "agentcore"
  }
}

resource "aws_ssm_parameter" "lambda_execute_query_arn" {
  name      = "/${var.APP}/${var.ENV}/agentcore/lambda-execute-query-arn"
  type      = "SecureString"
  value     = aws_lambda_function.execute_query.arn
  key_id    = data.aws_kms_key.ssm_key.arn
  overwrite = true

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "agentcore"
  }
}

resource "aws_ssm_parameter" "agent_core_role_arn" {
  name      = "/${var.APP}/${var.ENV}/agentcore/agent-core-role-arn"
  type      = "SecureString"
  value     = aws_iam_role.agent_core_role.arn
  key_id    = data.aws_kms_key.ssm_key.arn
  overwrite = true

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "agentcore"
  }
}

resource "aws_ssm_parameter" "lambda_web_search_arn" {
  name      = "/${var.APP}/${var.ENV}/agentcore/lambda-web-search-arn"
  type      = "SecureString"
  value     = aws_lambda_function.web_search.arn
  key_id    = data.aws_kms_key.ssm_key.arn
  overwrite = true

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "agentcore"
  }
}

resource "aws_ssm_parameter" "cognito_domain" {
  name      = "/${var.APP}/${var.ENV}/agentcore/cognito-domain"
  type      = "SecureString"
  value     = aws_cognito_user_pool_domain.agentcore.domain
  key_id    = data.aws_kms_key.ssm_key.arn
  overwrite = true

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "agentcore"
  }
}

resource "aws_ssm_parameter" "memory_id" {
  name      = "/${var.APP}/${var.ENV}/agentcore/memory-id"
  type      = "SecureString"
  value     = aws_bedrockagentcore_memory.this.id
  key_id    = data.aws_kms_key.ssm_key.arn
  overwrite = true

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "agentcore"
  }
}

# Temporary password for the demo user. Valid only until the first sign-in
# (Cognito forces a change). Retrieve with `make get-agentcore-demo-password`.
resource "aws_ssm_parameter" "demo_user_temp_password" {
  name      = "/${var.APP}/${var.ENV}/agentcore/demo-user-temp-password"
  type      = "SecureString"
  value     = random_password.demo_user_temp.result
  key_id    = data.aws_kms_key.ssm_key.arn
  overwrite = true

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "agentcore"
  }
}
