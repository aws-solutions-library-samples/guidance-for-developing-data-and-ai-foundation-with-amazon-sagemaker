// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# ---------------------------------------------------------------------------
# Lake Formation permissions for the AgentCore Lambda role
#
# The agent queries the data-lake modules' own Iceberg tables. Those tables
# are the ones the data-lake loader jobs write into, so they always reflect the
# latest committed data, and their schemas are owned by the data lakes.
#
# The tables the agent may read are looked up below. The lookups only read the
# data lakes' existing tables and create nothing. A missing table fails
# terraform plan with a clear error, which means the corresponding data-lake
# modules have to be deployed first. To expose another dataset, add a lookup
# and an entry in local.agent_tables.
#
# Grants are read-only and table-level: DESCRIBE on each database so the agent
# can see it, and SELECT and DESCRIBE on each named table only. These tables
# belong to other modules, so the agent must not be able to create, alter, or
# drop anything in them.
# ---------------------------------------------------------------------------

data "aws_glue_catalog_table" "equity_trade" {
  database_name = "equity_trade_s3_glue_s3"
  name          = "equity_trade_s3_glue_s3_iceberg"
}

data "aws_glue_catalog_table" "equity_price" {
  database_name = "equity_price_s3_glue_s3"
  name          = "equity_price_s3_glue_s3_iceberg"
}

locals {
  # Keyed by database name, one table per database.
  agent_tables = {
    (data.aws_glue_catalog_table.equity_trade.database_name) = data.aws_glue_catalog_table.equity_trade
    (data.aws_glue_catalog_table.equity_price.database_name) = data.aws_glue_catalog_table.equity_price
  }
}

resource "aws_lakeformation_permissions" "lambda_database" {
  for_each = local.agent_tables

  principal   = aws_iam_role.agentcore_lambda_role.arn
  permissions = ["DESCRIBE"]

  database {
    name = each.value.database_name
  }
}

resource "aws_lakeformation_permissions" "lambda_tables" {
  for_each = local.agent_tables

  principal   = aws_iam_role.agentcore_lambda_role.arn
  permissions = ["SELECT", "DESCRIBE"]

  table {
    database_name = each.value.database_name
    name          = each.value.name
  }
}
