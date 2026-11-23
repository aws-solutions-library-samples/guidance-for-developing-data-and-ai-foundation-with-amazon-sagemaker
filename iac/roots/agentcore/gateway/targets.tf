// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

// ---------------------------------------------------------------------------
// Gateway targets — generated from local.tools (main.tf) via for_each.
//
// Each target exposes a Lambda tool over MCP for client-side agents to
// orchestrate. The gateway is a pure tool server; clients bring their own
// LLM and system prompt.
//
// No changes needed here when adding a new tool — just update local.tools.
// ---------------------------------------------------------------------------

resource "aws_bedrockagentcore_gateway_target" "this" {
  for_each = local.tools

  name               = each.value.name
  gateway_identifier = aws_bedrockagentcore_gateway.this.gateway_id

  credential_provider_configuration {
    gateway_iam_role {}
  }

  target_configuration {
    mcp {
      lambda {
        lambda_arn = data.aws_ssm_parameter.lambda_arns[each.key].value

        tool_schema {
          inline_payload {
            name        = each.value.name
            description = each.value.description

            input_schema {
              type = "object"

              dynamic "property" {
                for_each = each.value.properties
                content {
                  name     = property.value.name
                  type     = property.value.type
                  required = property.value.required
                }
              }
            }
          }
        }
      }
    }
  }
}
