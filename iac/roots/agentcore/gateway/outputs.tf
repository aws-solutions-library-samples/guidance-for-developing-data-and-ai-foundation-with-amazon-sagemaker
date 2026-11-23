// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

// ---------------------------------------------------------------------------
// Outputs and SSM exports for downstream consumers (tests, notebooks).
//
// SSM parameters allow clients to discover the gateway URL without
// hard-coding Terraform remote state references.
// ---------------------------------------------------------------------------

resource "aws_ssm_parameter" "gateway_url" {
  name      = "/${var.APP}/${var.ENV}/agentcore/gateway-url"
  type      = "String"
  value     = aws_bedrockagentcore_gateway.this.gateway_url
  overwrite = true
  tags      = local.tags
}

output "gateway_url" {
  description = "AgentCore gateway endpoint URL"
  value       = aws_bedrockagentcore_gateway.this.gateway_url
}

output "gateway_id" {
  description = "AgentCore gateway identifier"
  value       = aws_bedrockagentcore_gateway.this.gateway_id
}
