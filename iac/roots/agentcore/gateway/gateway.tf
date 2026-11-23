// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

// ---------------------------------------------------------------------------
// AgentCore MCP Gateway — exposes Lambda-backed tools over the MCP protocol
// with Cognito JWT authentication.
//
// The gateway delegates credential management to its own IAM role (provisioned
// in the backend workstream) and validates caller tokens via the Cognito OIDC
// discovery endpoint. To support additional OAuth providers, add entries to
// allowed_clients or switch authorizer_type to a custom Lambda authorizer.
// ---------------------------------------------------------------------------

resource "aws_bedrockagentcore_gateway" "this" {
  name     = "${var.APP}-${var.ENV}-agentcore-gateway"
  role_arn = data.aws_ssm_parameter.agent_core_role_arn.value

  protocol_type   = "MCP"
  exception_level = "DEBUG"
  authorizer_type = "CUSTOM_JWT"

  authorizer_configuration {
    custom_jwt_authorizer {
      discovery_url   = "https://cognito-idp.${var.AWS_PRIMARY_REGION}.amazonaws.com/${data.aws_ssm_parameter.cognito_user_pool_id.value}/.well-known/openid-configuration"
      allowed_clients = [data.aws_ssm_parameter.cognito_app_client_id.value]
    }
  }

  tags = local.tags
}
