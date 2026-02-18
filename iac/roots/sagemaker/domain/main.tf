// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

terraform {
  required_version = ">= 1.8.0"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_kms_key" "ssm_kms_key" {

  provider = aws.primary
  key_id   = "alias/${var.SSM_KMS_KEY_ALIAS}"
}

data "aws_kms_key" "domain_kms_key" {

  provider = aws.primary
  key_id   = "alias/${var.DOMAIN_KMS_KEY_ALIAS}"
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.id
}
