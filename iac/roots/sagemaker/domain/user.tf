// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_ssoadmin_instances" "identity_center" {}

locals {
  # Parse the JSON string from SSM Parameter Store
  json_data = jsondecode(local.SMUS_DOMAIN_USER_MAPPINGS)

  # Extract user IDs using nested for expressions
  user_emails = flatten([
    for domain, groups in local.json_data : [
      for group, users in groups : users
    ]
  ])

  # Extract all unique emails from Domain Owner group across all domains
  domain_owner_emails = flatten([
    for domain, groups in local.json_data : groups["Domain Owner"]
  ])
}

# Data source to look up user IDs by email
data "aws_identitystore_user" "users" {
  for_each = toset(nonsensitive(local.user_emails))

  identity_store_id = data.aws_ssoadmin_instances.identity_center.identity_store_ids[0]
  alternate_identifier {
    unique_attribute {
      attribute_path  = "UserName"
      attribute_value = each.key
    }
  }
}

# Data source to look up domain owners by email
data "aws_identitystore_user" "domain_owners" {
  for_each = toset(nonsensitive(local.domain_owner_emails))

  identity_store_id = data.aws_ssoadmin_instances.identity_center.identity_store_ids[0]
  alternate_identifier {
    unique_attribute {
      attribute_path  = "UserName"
      attribute_value = each.key
    }
  }
}

# Create user profiles using native AWSCC resource
resource "awscc_datazone_user_profile" "users" {
  for_each = toset(nonsensitive(local.user_emails))

  depends_on = [aws_datazone_domain.smus_domain]

  domain_identifier = local.domain_id
  user_identifier   = data.aws_identitystore_user.users[each.key].user_id
  user_type         = "SSO_USER"
  status            = "ASSIGNED"

  lifecycle {
    ignore_changes = [status]
  }
}

# Add domain owners to the root domain unit using native AWSCC resource
resource "awscc_datazone_owner" "domain_owners" {
  for_each = toset(nonsensitive(local.domain_owner_emails))

  depends_on = [
    aws_datazone_domain.smus_domain,
    awscc_datazone_user_profile.users
  ]

  domain_identifier = local.domain_id
  entity_identifier = local.root_domain_unit_id
  entity_type       = "DOMAIN_UNIT"

  owner = {
    user = {
      user_identifier = data.aws_identitystore_user.domain_owners[each.key].user_id
    }
  }
}
