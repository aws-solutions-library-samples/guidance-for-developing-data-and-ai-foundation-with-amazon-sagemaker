// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

// ---------------------------------------------------------------------------
// AgentCore Demo — S3 static site + API Gateway + Lambda
//
// Hosts a chat UI on S3 and proxies agent requests through API Gateway to a
// Lambda that runs a Strands agent connected to the AgentCore MCP gateway.
// ---------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.id
  prefix     = "${var.APP}-${var.ENV}"
  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "agentcore-demo"
  }
}

# ---------------------------------------------------------------------------
# Auth — Cognito JWT authorizer
# ---------------------------------------------------------------------------

data "aws_ssm_parameter" "cognito_user_pool_id" {
  name = "/${var.APP}/${var.ENV}/agentcore/cognito-user-pool-id"
}

data "aws_ssm_parameter" "cognito_domain" {
  name = "/${var.APP}/${var.ENV}/agentcore/cognito-domain"
}

resource "aws_cognito_user_pool_client" "demo" {
  name         = "${local.prefix}-agentcore-demo-client"
  user_pool_id = nonsensitive(data.aws_ssm_parameter.cognito_user_pool_id.value)

  generate_secret                      = false
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email"]
  allowed_oauth_flows_user_pool_client = true
  callback_urls                        = [aws_apigatewayv2_stage.default.invoke_url]
  logout_urls                          = [aws_apigatewayv2_stage.default.invoke_url]

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  supported_identity_providers = ["COGNITO"]
}

# ---------------------------------------------------------------------------
# Compute — Lambda function + layer
# ---------------------------------------------------------------------------

resource "null_resource" "chat_layer_build" {
  triggers = {
    requirements = filemd5("${path.module}/lambda-functions/requirements.txt")
  }

  provisioner "local-exec" {
    command = <<-EOT
      rm -rf ${path.module}/lambda-layers/chat/python
      mkdir -p ${path.module}/lambda-layers/chat/python
      pip3 install -r ${path.module}/lambda-functions/requirements.txt \
        -t ${path.module}/lambda-layers/chat/python -q \
        --platform manylinux2014_x86_64 --python-version 3.13 --only-binary=:all:
    EOT
  }
}

data "archive_file" "chat_layer" {
  type        = "zip"
  source_dir  = "${path.module}/lambda-layers/chat"
  output_path = "${path.module}/lambda-layers/chat.zip"
  depends_on  = [null_resource.chat_layer_build]
}

resource "aws_lambda_layer_version" "chat" {
  layer_name          = "${local.prefix}-agentcore-demo-chat"
  filename            = data.archive_file.chat_layer.output_path
  source_code_hash    = data.archive_file.chat_layer.output_base64sha256
  compatible_runtimes = ["python3.13"]
}

data "archive_file" "chat" {
  type        = "zip"
  source_dir  = "${path.module}/lambda-functions/chat_src"
  output_path = "${path.module}/lambda-functions/chat.zip"
}

resource "aws_iam_role" "chat_lambda" {
  name = "${local.prefix}-agentcore-demo-lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = local.tags
}

resource "aws_iam_role_policy" "chat_lambda" {
  name = "demo-permissions"
  role = aws_iam_role.chat_lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = "arn:aws:ssm:${local.region}:${local.account_id}:parameter/${var.APP}/${var.ENV}/agentcore/*"
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock-agentcore:CreateEvent",
          "bedrock-agentcore:ListEvents",
          "bedrock-agentcore:GetEvent",
          "bedrock-agentcore:ListSessions",
          "bedrock-agentcore:RetrieveMemoryRecords"
        ]
        Resource = "arn:aws:bedrock-agentcore:${local.region}:${local.account_id}:memory/*"
      },
      {
        Effect   = "Allow"
        Action   = ["cognito-idp:DescribeUserPoolClient", "cognito-idp:DescribeUserPool"]
        Resource = "arn:aws:cognito-idp:${local.region}:${local.account_id}:userpool/*"
      },
      {
        Effect = "Allow"
        Action = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
        Resource = [
          "arn:aws:bedrock:*::foundation-model/*",
          "arn:aws:bedrock:${local.region}:${local.account_id}:inference-profile/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:${local.region}:${local.account_id}:*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.site.arn}/*"
      },
      {
        Effect    = "Allow"
        Action    = ["kms:Decrypt"]
        Resource  = "*"
        Condition = { StringEquals = { "kms:CallerAccount" = local.account_id } }
      }
    ]
  })
}

resource "aws_lambda_function" "chat" {
  #checkov:skip=CKV_AWS_116: "DLQ not needed for demo"
  #checkov:skip=CKV_AWS_173: "Env vars not sensitive"
  #checkov:skip=CKV_AWS_272: "Code signing not required"

  function_name    = "${local.prefix}-agentcore-demo-chat"
  role             = aws_iam_role.chat_lambda.arn
  handler          = "chat.lambda_handler"
  runtime          = "python3.13"
  timeout          = 120
  memory_size      = 512
  filename         = data.archive_file.chat.output_path
  source_code_hash = data.archive_file.chat.output_base64sha256

  layers = [aws_lambda_layer_version.chat.arn]

  environment {
    variables = {
      DEPLOY_REGION  = var.AWS_PRIMARY_REGION
      SSM_PREFIX     = "/${var.APP}/${var.ENV}/agentcore"
      SITE_BUCKET    = aws_s3_bucket.site.id
      MEMORY_ID      = "" # Populated from SSM at runtime
      ALLOWED_ORIGIN = aws_apigatewayv2_stage.default.invoke_url
    }
  }

  tags = local.tags
}

# ---------------------------------------------------------------------------
# API Gateway — HTTP API with JWT-protected chat route
# ---------------------------------------------------------------------------

resource "aws_apigatewayv2_api" "chat" {
  name          = "${local.prefix}-agentcore-demo"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization"]
    max_age       = 3600
  }

  tags = local.tags
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.chat.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.chat.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "cognito-jwt"

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.demo.id]
    issuer   = "https://cognito-idp.${local.region}.amazonaws.com/${nonsensitive(data.aws_ssm_parameter.cognito_user_pool_id.value)}"
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.chat.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.chat.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "chat" {
  api_id             = aws_apigatewayv2_api.chat.id
  route_key          = "POST /chat"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "ui" {
  api_id    = aws_apigatewayv2_api.chat.id
  route_key = "GET /"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_lambda_permission" "apigw" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chat.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.chat.execution_arn}/*/*"
}

# ---------------------------------------------------------------------------
# Static assets — S3 bucket + index.html
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "site" {
  bucket = "${local.account_id}-${local.prefix}-agentcore-demo"
  tags   = local.tags
}

# The bucket is read only by the chat Lambda, never directly by browsers.
resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

locals {
  # Rendered once so that content and etag are computed from the same string,
  # keeping the object in sync with its etag and the plan stable.
  index_html = templatefile("${path.module}/static/index.html", {
    API_URL        = "${aws_apigatewayv2_stage.default.invoke_url}chat"
    COGNITO_DOMAIN = "https://${nonsensitive(data.aws_ssm_parameter.cognito_domain.value)}.auth.${local.region}.amazoncognito.com"
    CLIENT_ID      = aws_cognito_user_pool_client.demo.id
    REDIRECT_URI   = aws_apigatewayv2_stage.default.invoke_url
  })
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.site.id
  key          = "index.html"
  content      = local.index_html
  content_type = "text/html"
  etag         = md5(local.index_html)
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

output "site_url" {
  description = "Chat UI URL"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "api_url" {
  description = "Chat API endpoint"
  value       = "${aws_apigatewayv2_stage.default.invoke_url}chat"
}
