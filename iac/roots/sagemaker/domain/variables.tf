// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

variable "APP" {

  type = string
}

variable "ENV" {

  type = string
}

variable "AWS_PRIMARY_REGION" {

  type = string
}

variable "AWS_SECONDARY_REGION" {

  type = string
}

variable "SSM_KMS_KEY_ALIAS" {

  type = string
}

variable "blueprint_ids" {
  type        = list(string)
  description = "List of environment blueprint IDs to attach. This is a pre-defined list of identifiers already available in an account"
  default = []
}

variable "domain_user_ids" {
  type        = list(string)
  description = "List of domain user IDs to attach to the domain. Use the userId attribute from Identity Center."
  default = []
}

variable "domain_admin_ids" {
  type        = list(string)
  description = "List of domain admin IDs to attach to the domain. Use the userId attribute from Identity Center."
  default = []
}

variable "project_profiles" {
  type = list(object({
    name = string
    description = string
    status = string
    environmentConfigurations = list(object({
      awsAccount = object({
        awsAccountId = string
      })
      awsRegion = object({
        regionName = string
      })
      configurationParameters = object({
        parameterOverrides = optional(list(object({
          isEditable = bool
          name       = string
          value      = optional(string, "")
        })))
        resolvedParameters = list(object({
          isEditable = bool
          name       = string
          value = optional(string, "")
        }))
      })
      deploymentMode         = string
      deploymentOrder        = optional(number)
      description            = string
      environmentBlueprintId = string
      name                   = string
    }))
  }))

  description = "Environment configuration for each project profile created within the domain"
}

variable "DOMAIN_KMS_KEY_ALIAS" {
  type = string
}

variable SMUS_DOMAIN_VPC_ID {
  type = string
}

variable SMUS_DOMAIN_PRIVATE_SUBNET_IDS {
  type = string
}

variable SMUS_DOMAIN_AVAILABILITY_ZONE_NAMES {
  type = string
}
