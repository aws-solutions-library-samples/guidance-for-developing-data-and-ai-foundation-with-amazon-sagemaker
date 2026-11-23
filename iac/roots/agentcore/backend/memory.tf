// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# ---------------------------------------------------------------------------
# AgentCore Memory, a managed persistence layer for agent conversations.
#
# Strategies are added as separate resources after the memory becomes ACTIVE.
# Namespaces use {actorId} (user email) and {sessionId} to partition data
# per user and session automatically.
# ---------------------------------------------------------------------------

resource "aws_bedrockagentcore_memory" "this" {
  name                  = "${var.APP}_${var.ENV}_agentcore_memory"
  description           = "Agent memory for DAIVI financial analyst"
  event_expiry_duration = 90

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "agentcore-memory"
  }
}

# Each strategy resource issues an UpdateMemory call against the same memory,
# and AgentCore Memory accepts only one mutation at a time. Concurrent calls
# are rejected with "Memory is in transitional state UPDATING", so the
# strategies are chained with depends_on and Terraform never runs two at once.
#
# The provider waits for completion on both paths: about 2.5 min per strategy
# to reach ACTIVE on create, and 2.5 to 5 min per delete. The depends_on
# ordering is therefore enough on the create path, and the time_sleep
# resources add no create-side delay.
#
# On destroy, Terraform tears the chain down in reverse order: semantic, wait,
# preferences, wait, summary. Each time_sleep holds 150s between deletes so the
# memory has settled before the next one is issued, guarding against a
# parallel delete leaving a strategy in the service after it is removed from
# state. This adds about 5 minutes to a teardown.

resource "aws_bedrockagentcore_memory_strategy" "summary" {
  memory_id  = aws_bedrockagentcore_memory.this.id
  name       = "SessionSummarizer"
  type       = "SUMMARIZATION"
  namespaces = ["/summaries/{actorId}/{sessionId}/"]
}

resource "time_sleep" "after_summary" {
  depends_on       = [aws_bedrockagentcore_memory_strategy.summary]
  destroy_duration = "150s"
}

resource "aws_bedrockagentcore_memory_strategy" "preferences" {
  memory_id  = aws_bedrockagentcore_memory.this.id
  name       = "PreferenceLearner"
  type       = "USER_PREFERENCE"
  namespaces = ["/preferences/{actorId}/"]

  depends_on = [time_sleep.after_summary]
}

resource "time_sleep" "after_preferences" {
  depends_on       = [aws_bedrockagentcore_memory_strategy.preferences]
  destroy_duration = "150s"
}

resource "aws_bedrockagentcore_memory_strategy" "semantic" {
  memory_id  = aws_bedrockagentcore_memory.this.id
  name       = "FactExtractor"
  type       = "SEMANTIC"
  namespaces = ["/facts/{actorId}/"]

  depends_on = [time_sleep.after_preferences]
}


# ---------------------------------------------------------------------------
# CloudWatch log delivery for AgentCore Memory APPLICATION_LOGS.
#
# AgentCore Memory does not auto-create a log group. We configure vended log
# delivery so memory event creation, retrieval, and strategy processing logs
# stream into CloudWatch Logs at /aws/vendedlogs/bedrock-agentcore/memory/<id>.
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "memory" {
  name              = "/aws/vendedlogs/bedrock-agentcore/memory/${aws_bedrockagentcore_memory.this.id}"
  retention_in_days = 30

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "agentcore-memory-logs"
  }
}

resource "aws_cloudwatch_log_delivery_source" "memory" {
  name         = "${var.APP}-${var.ENV}-agentcore-memory-source"
  log_type     = "APPLICATION_LOGS"
  resource_arn = aws_bedrockagentcore_memory.this.arn
}

resource "aws_cloudwatch_log_delivery_destination" "memory" {
  name          = "${var.APP}-${var.ENV}-agentcore-memory-destination"
  output_format = "json"

  delivery_destination_configuration {
    destination_resource_arn = aws_cloudwatch_log_group.memory.arn
  }
}

resource "aws_cloudwatch_log_delivery" "memory" {
  delivery_source_name     = aws_cloudwatch_log_delivery_source.memory.name
  delivery_destination_arn = aws_cloudwatch_log_delivery_destination.memory.arn
}
