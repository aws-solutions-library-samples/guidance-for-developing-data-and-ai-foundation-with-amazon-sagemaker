// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

output "cognito_user_pool_id" {
  description = "Cognito user pool identifier"
  value       = aws_cognito_user_pool.agentcore.id
}

output "cognito_app_client_id" {
  description = "Cognito application client identifier"
  value       = aws_cognito_user_pool_client.agentcore.id
}

output "cognito_endpoint" {
  description = "Cognito OAuth endpoint URL"
  value       = "https://${aws_cognito_user_pool_domain.agentcore.domain}.auth.${data.aws_region.current.id}.amazoncognito.com"
}

output "lambda_get_databases_arn" {
  description = "ARN of the get-databases Lambda function"
  value       = aws_lambda_function.get_databases.arn
}

output "lambda_get_database_tables_arn" {
  description = "ARN of the get-database-tables Lambda function"
  value       = aws_lambda_function.get_database_tables.arn
}

output "lambda_execute_query_arn" {
  description = "ARN of the execute-query Lambda function"
  value       = aws_lambda_function.execute_query.arn
}

output "agent_core_role_arn" {
  description = "ARN of the AgentCore IAM role"
  value       = aws_iam_role.agent_core_role.arn
}

output "lambda_kms_key_arn" {
  description = "ARN of the KMS key used for Lambda encryption"
  value       = module.lambda_kms_key.arn
}

output "agent_tables" {
  description = "Data-lake tables the agent has read access to, as database.table"
  value       = [for t in local.agent_tables : "${t.database_name}.${t.name}"]
}

output "lambda_web_search_arn" {
  description = "ARN of the web-search Lambda function"
  value       = aws_lambda_function.web_search.arn
}

output "demo_user_temp_password" {
  description = "Temporary password for the demo user, valid until the first sign-in"
  value       = random_password.demo_user_temp.result
  sensitive   = true
}
