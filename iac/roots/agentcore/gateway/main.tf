// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

// ---------------------------------------------------------------------------
// Shared locals and SSM lookups for the gateway workstream.
//
// This file wires the gateway to backend resources (Cognito, Lambdas, IAM)
// via SSM parameters, keeping the two workstreams independently deployable.
// The gateway is a pure MCP tool server — clients bring their own agent.
//
// HOW TO ADD A NEW TOOL:
//   1. Add its SSM key to local.tools below (the key must match the SSM
//      parameter name suffix published by the backend).
//   2. That's it — targets.tf iterates local.tools via for_each.
// ---------------------------------------------------------------------------

locals {
  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "agentcore"
  }
}

// SSM lookups for Cognito auth (published by the backend workstream)

data "aws_ssm_parameter" "cognito_app_client_id" {
  name = "/${var.APP}/${var.ENV}/agentcore/cognito-app-client-id"
}

data "aws_ssm_parameter" "cognito_endpoint" {
  name = "/${var.APP}/${var.ENV}/agentcore/cognito-endpoint"
}

data "aws_ssm_parameter" "cognito_user_pool_id" {
  name = "/${var.APP}/${var.ENV}/agentcore/cognito-user-pool-id"
}

data "aws_ssm_parameter" "agent_core_role_arn" {
  name = "/${var.APP}/${var.ENV}/agentcore/agent-core-role-arn"
}

// ---------------------------------------------------------------------------
// Tool registry — single source of truth for all gateway targets.
//
// Each entry defines:
//   ssm_key     – SSM parameter suffix for the Lambda ARN
//   name        – MCP tool name exposed to clients
//   description – shown in tools/list so clients know what the tool does
//   properties  – ordered list of input parameters (empty = no inputs)
// ---------------------------------------------------------------------------

locals {
  tools = {
    databases = {
      ssm_key     = "lambda-get-databases-arn"
      name        = "get-databases"
      description = "Returns the list of Glue databases"
      properties  = []
    }
    tables = {
      ssm_key     = "lambda-get-database-tables-arn"
      name        = "get-database-tables"
      description = "Returns the table schemas for a given database"
      properties = [
        { name = "database", type = "string", required = true }
      ]
    }
    query = {
      ssm_key     = "lambda-execute-query-arn"
      name        = "execute-query"
      description = "Executes a SQL query against a specified database and returns results"
      properties = [
        { name = "database", type = "string", required = true },
        { name = "query", type = "string", required = true }
      ]
    }
    web_search = {
      ssm_key     = "lambda-web-search-arn"
      name        = "web-search"
      description = "Searches the web for current information using keywords"
      properties = [
        { name = "keywords", type = "string", required = true },
        { name = "max_results", type = "string", required = false }
      ]
    }
  }
}

// Batch SSM lookup — one data source per tool, driven by the registry above.

data "aws_ssm_parameter" "lambda_arns" {
  for_each = local.tools
  name     = "/${var.APP}/${var.ENV}/agentcore/${each.value.ssm_key}"
}
