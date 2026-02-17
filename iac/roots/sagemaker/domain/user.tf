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

  # Convert to lists for sequential processing
  user_emails_list         = tolist(toset(nonsensitive(local.user_emails)))
  domain_owner_emails_list = tolist(toset(nonsensitive(local.domain_owner_emails)))

  # Detect operating system
  # We need different execution strategies because:
  # 1. SSO Admin service has concurrency limitations - multiple simultaneous operations cause conflicts
  # 2. Unix/Linux/macOS support bash scripting for sequential execution with retry logic
  # 3. Windows environments don't support bash syntax, so we fall back to Terraform resources
  # 4. Sequential creation eliminates "conflicting operation in process" errors from Identity Center
  is_windows = substr(pathexpand("~"), 0, 1) != "/"
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

# Add wait time for SSO Admin operations to complete
resource "time_sleep" "wait_for_sso_operations" {
  depends_on = [
    aws_datazone_domain.smus_domain,
    data.aws_identitystore_user.users,
    data.aws_identitystore_user.domain_owners
  ]
  create_duration = "30s"
}

# Sequential user creation for Unix/Linux/macOS environments (bash scripting with retry logic)
resource "null_resource" "create_user_profiles_sequentially" {
  count = local.is_windows ? 0 : 1

  depends_on = [
    aws_datazone_domain.smus_domain,
    time_sleep.wait_for_sso_operations
  ]

  triggers = {
    user_emails = join(",", local.user_emails_list)
    domain_id   = local.domain_id
  }

  provisioner "local-exec" {
    command = <<-EOF
      echo "Creating DataZone user profiles sequentially on Unix/Linux/macOS..."
      for email in ${join(" ", [for email in local.user_emails_list : "\"${email}\""])}; do
        echo "Creating user profile for $email"
        
        # Get user ID from Identity Center
        user_id=$(aws identitystore list-users \
          --identity-store-id ${data.aws_ssoadmin_instances.identity_center.identity_store_ids[0]} \
          --filters AttributePath=UserName,AttributeValue="$email" \
          --query 'Users[0].UserId' --output text)
        
        if [ "$user_id" != "None" ] && [ "$user_id" != "" ]; then
          # Create user profile with retry logic (correct AWS CLI syntax)
          for attempt in {1..3}; do
            echo "Attempt $attempt: Creating user profile for $email (User ID: $user_id)"
            if aws datazone create-user-profile \
              --domain-identifier ${local.domain_id} \
              --user-identifier "$user_id" \
              --user-type SSO_USER; then
              echo "Successfully created user profile for $email"
              break
            else
              echo "Failed attempt $attempt for $email, retrying in 10 seconds..."
              sleep 10
            fi
          done
        else
          echo "Warning: Could not find user ID for $email"
        fi
        
        echo "Waiting 15 seconds before next user..."
        sleep 15
      done
      echo "Completed creating all user profiles"
    EOF
  }
}

# Fallback for Windows environments (Terraform resources, may need -parallelism=1 if conflicts occur)
resource "awscc_datazone_user_profile" "user_windows" {
  for_each = local.is_windows ? toset(nonsensitive(local.user_emails)) : toset([])

  depends_on = [
    aws_datazone_domain.smus_domain,
    time_sleep.wait_for_sso_operations
  ]

  domain_identifier = local.domain_id
  user_identifier   = data.aws_identitystore_user.users[each.key].user_id
  user_type         = "SSO_USER"
  status            = "ASSIGNED"

  # Add lifecycle rule to handle conflicts and prevent unnecessary recreation
  lifecycle {
    ignore_changes        = [status]
    create_before_destroy = false
  }
}

# Platform-specific wait resources
resource "time_sleep" "wait_for_user_profiles_unix" {
  count           = local.is_windows ? 0 : 1
  depends_on      = [null_resource.create_user_profiles_sequentially]
  create_duration = "15s"
}

# Add additional wait before triggering root owners - Windows
resource "time_sleep" "wait_for_user_profiles_windows" {
  count           = local.is_windows ? 1 : 0
  depends_on      = [awscc_datazone_user_profile.user_windows]
  create_duration = "30s"
}

# Platform-specific root owner assignment (Unix: bash with retry, Windows: direct CLI)
resource "null_resource" "add_root_owners_unix" {
  for_each   = local.is_windows ? toset([]) : toset(nonsensitive(local.domain_owner_emails))
  depends_on = [time_sleep.wait_for_user_profiles_unix]

  triggers = {
    domain_id = local.domain_id
    user_id   = data.aws_identitystore_user.domain_owners[each.key].user_id
  }

  provisioner "local-exec" {
    command = <<-EOF
      # Add retry logic for the AWS CLI command
      for i in {1..5}; do
        if aws datazone add-entity-owner \
          --domain-identifier ${local.domain_id} \
          --entity-type DOMAIN_UNIT \
          --entity-identifier ${local.root_domain_unit_id} \
          --owner '{"user": {"userIdentifier": "${data.aws_identitystore_user.domain_owners[each.key].user_id}"}}'; then
          echo "Successfully added entity owner on attempt $i"
          break
        else
          echo "Attempt $i failed, retrying in 30 seconds..."
          sleep 30
        fi
      done
    EOF
  }
}

resource "null_resource" "add_root_owners_windows" {
  for_each   = local.is_windows ? toset(nonsensitive(local.domain_owner_emails)) : toset([])
  depends_on = [time_sleep.wait_for_user_profiles_windows]

  triggers = {
    domain_id = local.domain_id
    user_id   = data.aws_identitystore_user.domain_owners[each.key].user_id
  }

  provisioner "local-exec" {
    command = "aws datazone add-entity-owner --domain-identifier ${local.domain_id} --entity-type DOMAIN_UNIT --entity-identifier ${local.root_domain_unit_id} --owner \"{\\\"user\\\": {\\\"userIdentifier\\\": \\\"${data.aws_identitystore_user.domain_owners[each.key].user_id}\\\"}}\""
  }
}