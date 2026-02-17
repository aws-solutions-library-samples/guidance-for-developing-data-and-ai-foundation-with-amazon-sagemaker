// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

resource "aws_datazone_environment_blueprint_configuration" "blueprint_configs" {

  for_each = toset(var.blueprint_ids)

  domain_id                = local.domain_id
  environment_blueprint_id = each.value
  enabled_regions          = ["${local.region}"]
  regional_parameters = {
    "${local.region}" : {
      "AZs" : local.SMUS_DOMAIN_AVAILABILITY_ZONE_NAMES
      "S3Location" : local.SMUS_PROJECTS_BUCKET_S3_URL
      "VpcId" : local.SMUS_DOMAIN_VPC_ID
      "Subnets" : local.SMUS_DOMAIN_PRIVATE_SUBNET_IDS
    }
  }

  manage_access_role_arn = aws_iam_role.smus_domain_manage_access_role.arn
  provisioning_role_arn  = local.SMUS_DOMAIN_PROVISIONING_ROLE_ARN
}

# Grant access to the root domain unit on all the blueprints

resource "awscc_datazone_policy_grant" "blueprint_policy_grants" {

  depends_on = [aws_datazone_environment_blueprint_configuration.blueprint_configs]
  for_each   = toset(var.blueprint_ids)

  domain_identifier = local.domain_id
  entity_identifier = "${local.account_id}:${each.value}"
  entity_type       = "ENVIRONMENT_BLUEPRINT_CONFIGURATION"
  policy_type       = "CREATE_ENVIRONMENT_FROM_BLUEPRINT"

  principal = {
    project = {
      project_designation = "CONTRIBUTOR"
      project_grant_filter = {
        domain_unit_filter = {
          domain_unit                = local.root_domain_unit_id
          include_child_domain_units = true
        }
      }
    }
  }

  detail = {
    create_environment_from_blueprint = "{}"
  }
}
