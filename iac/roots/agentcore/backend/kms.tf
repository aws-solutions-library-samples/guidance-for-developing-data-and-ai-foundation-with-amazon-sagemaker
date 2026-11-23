// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

module "lambda_kms_key" {
  source = "../../../templates/modules/kms"

  alias       = "${var.APP}-${var.ENV}-lambda-key"
  description = "KMS key for AgentCore Lambda function encryption"

  roles = [
    aws_iam_role.agentcore_lambda_role.arn
  ]

  services = [
    "lambda.${data.aws_region.current.id}.amazonaws.com"
  ]
}
