// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

resource "aws_cognito_user_pool" "agentcore" {
  name = "${var.APP}-${var.ENV}-agentcore-pool"

  # Disable self-registration — only admin-created users can log in
  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  auto_verified_attributes = ["email"]

  # Password history requires the Essentials or Plus feature plan, so the tier
  # is set explicitly rather than left to the account default.
  user_pool_tier = "ESSENTIALS"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true

    # Users cannot set a password that matches any of their last 5 passwords.
    password_history_size = 5
  }

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "agentcore"
  }
}

resource "aws_cognito_user_pool_domain" "agentcore" {
  domain       = "${var.APP}-${var.ENV}-agentcore-${local.account_id}"
  user_pool_id = aws_cognito_user_pool.agentcore.id
}

resource "aws_cognito_resource_server" "agentcore" {
  identifier   = "${var.APP}-${var.ENV}-agentcore-resource-server"
  name         = "${var.APP}-${var.ENV}-agentcore-resource-server"
  user_pool_id = aws_cognito_user_pool.agentcore.id

  scope {
    scope_name        = "read"
    scope_description = "Read access to AgentCore tools"
  }
}

# Machine-to-machine client (used by MCP gateway)
resource "aws_cognito_user_pool_client" "agentcore" {
  name         = "${var.APP}-${var.ENV}-agentcore-client"
  user_pool_id = aws_cognito_user_pool.agentcore.id

  generate_secret                      = true
  allowed_oauth_flows                  = ["client_credentials"]
  allowed_oauth_scopes                 = ["${aws_cognito_resource_server.agentcore.identifier}/read"]
  allowed_oauth_flows_user_pool_client = true

  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  supported_identity_providers = ["COGNITO"]
}

# The human login client (authorization_code flow) is defined in the demo
# root, because its callback and logout URLs point at the demo API Gateway
# stage URL, which only that root knows. This root defines only the
# machine-to-machine client used by the MCP gateway.

# Temporary password for the demo user. Generated per deployment and published
# to SSM (see ssm.tf). The special character set excludes characters that are
# awkward to copy from a terminal or that a shell would interpret.
resource "random_password" "demo_user_temp" {
  length           = 16
  special          = true
  override_special = "!#%^*-_=+"
  min_special      = 2
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
}

# Preconfigured demo user — temporary password forces change on first login
resource "aws_cognito_user" "demo" {
  user_pool_id       = aws_cognito_user_pool.agentcore.id
  username           = "daivi-agent@example.com"
  temporary_password = random_password.demo_user_temp.result

  attributes = {
    email          = "daivi-agent@example.com"
    email_verified = "true"
  }
}
