// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

locals {
  # Transform project_profiles from camelCase (tfvars) to snake_case (AWSCC resource)
  # Override awsAccountId and regionName with actual values from the current deployment
  project_profiles = [
    for profile in var.project_profiles : {
      name        = profile.name
      description = profile.description
      status      = profile.status

      environment_configurations = [
        for env_config in profile.environmentConfigurations : {
          deployment_mode          = env_config.deploymentMode
          deployment_order         = env_config.deploymentOrder
          name                     = env_config.name
          description              = env_config.description
          environment_blueprint_id = local.blueprint_name_to_id[env_config.environmentBlueprintName]
          aws_account = {
            aws_account_id = local.account_id
          }
          aws_region = {
            region_name = local.region
          }
          configuration_parameters = {
            resolved_parameters = [
              for param in env_config.configurationParameters.resolvedParameters : {
                is_editable = param.isEditable
                name        = param.name
                value       = param.value
              }
            ]
            parameter_overrides = env_config.configurationParameters.parameterOverrides != null ? [
              for param in env_config.configurationParameters.parameterOverrides : {
                is_editable = param.isEditable
                name        = param.name
                value       = param.value
              }
            ] : null
          }
        }
      ]
    }
  ]
}

# Create Project Profiles using native AWSCC resource
resource "awscc_datazone_project_profile" "project_profiles" {

  for_each = { for idx, profile in local.project_profiles : tostring(idx) => profile }

  domain_identifier          = local.domain_id
  name                       = each.value.name
  description                = each.value.description
  status                     = each.value.status
  environment_configurations = each.value.environment_configurations
}

locals {

  # Sort keys to ensure consistent ordering matching the input list
  sorted_profile_keys = sort(keys(awscc_datazone_project_profile.project_profiles))

  profile_names = [
    for k in local.sorted_profile_keys : awscc_datazone_project_profile.project_profiles[k].name
  ]

  # Create an array of profile IDs
  profile_ids = [
    for k in local.sorted_profile_keys : awscc_datazone_project_profile.project_profiles[k].project_profile_id
  ]
}

# Save each profile_name -> profile_id mapping to SSM parameter store
resource "aws_ssm_parameter" "smus_project_profile_ids" {

  count  = length(local.profile_names)
  name   = "/${var.APP}/${var.ENV}/project_profile_${count.index + 1}"
  value  = "${local.profile_ids[count.index]}:${local.profile_names[count.index]}"
  type   = "SecureString"
  key_id = data.aws_kms_key.ssm_kms_key.key_id

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "SMUS Domain"
  }
}

# Grant access to all the Identity Center users on all the newly created project profiles
resource "awscc_datazone_policy_grant" "project_profile_policy_grants" {

  depends_on = [awscc_datazone_project_profile.project_profiles]

  domain_identifier = local.domain_id
  entity_identifier = local.root_domain_unit_id
  entity_type       = "DOMAIN_UNIT"
  policy_type       = "CREATE_PROJECT_FROM_PROJECT_PROFILE"

  principal = {
    user = {
      all_users_grant_filter = "{}"
    }
  }

  detail = {
    create_project_from_project_profile = {
      project_profiles = local.profile_ids
    }
  }
}
