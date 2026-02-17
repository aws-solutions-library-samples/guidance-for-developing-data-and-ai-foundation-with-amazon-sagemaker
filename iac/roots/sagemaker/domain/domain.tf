// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

resource "aws_datazone_domain" "smus_domain" {

  name                  = "Corporate"
  description           = "SageMaker Unified Studio Domain"
  domain_execution_role = local.SMUS_DOMAIN_EXECUTION_ROLE_ARN
  service_role          = local.SMUS_DOMAIN_SERVICE_ROLE_ARN
  domain_version        = "V2"
  kms_key_identifier    = data.aws_kms_key.domain_kms_key.arn

  single_sign_on {
    type            = "IAM_IDC"
    user_assignment = "MANUAL"
  }

  timeouts {
    create = "15m"
    delete = "15m"
  }
}

locals {
  domain_id           = aws_datazone_domain.smus_domain.id
  root_domain_unit_id = aws_datazone_domain.smus_domain.root_domain_unit_id
}

# Save the domain id in SSM Parameter Store
resource "aws_ssm_parameter" "smus_domain_id" {

  name   = "/${var.APP}/${var.ENV}/smus_domain_id"
  type   = "SecureString"
  value  = local.domain_id
  key_id = data.aws_kms_key.ssm_kms_key.key_id

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "SMUS Domain"
  }
}
