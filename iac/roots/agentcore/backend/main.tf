// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# ---------------------------------------------------------------------------
# Data sources — existing infrastructure
# ---------------------------------------------------------------------------

data "aws_kms_key" "ssm_key" {
  key_id = "alias/${var.APP}-${var.ENV}-systems-manager-secret-key"
}

locals {
  athena_output_bucket = "${local.account_id}-${var.APP}-${var.ENV}-athena-output"
  athena_workgroup     = "${var.APP}-${var.ENV}-workgroup"
}
