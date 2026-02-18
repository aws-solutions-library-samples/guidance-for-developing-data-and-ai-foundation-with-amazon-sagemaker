// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

variable "AWS_ACCOUNT_ID" {

  type = string
}

variable "APP" {

  type = string
}

variable "ENV" {

  type = string
}

variable "AWS_PRIMARY_REGION" {

  type = string
}

variable "S3_KMS_KEY_ALIAS" {

  type = string
}

variable "S3_TABLES_KMS_KEY_ALIAS" {

  type = string
}

variable "INSTANCE_TYPE" {

  type        = string
  default     = "t3.xlarge"
  description = "EC2 instance type"
}

variable "ROOT_VOLUME_SIZE" {

  type        = number
  default     = 100
  description = "Size of the root volume in GB"
}

variable "DATA_VOLUME_SIZE" {

  type        = number
  default     = 200
  description = "Size of the data volume in GB"
}

variable "SPLUNK_VERSION" {

  type        = string
  default     = "9.0.1"
  description = "Splunk version to install"
}

variable "SPLUNK_BUILD" {

  type        = string
  default     = "82c987350fde"
  description = "Splunk build version to install"
}

variable "ASSOCIATE_PUBLIC_IP" {

  type        = bool
  default     = false
  description = "Whether to associate a public IP address"
}

variable "GLUE_ROLE_NAME" {

  type = string
}

variable "SPLUNK_EC2_PROFILE_NAME" {

  type = string
}

variable "USAGE_ICEBERG_BUCKET" {

  type = string
}

variable "GLUE_SPARK_LOGS_BUCKET" {

  type = string
}

variable "GLUE_TEMP_BUCKET" {

  type = string
}

variable "GLUE_KMS_KEY_ALIAS" {

  type = string
}

variable "CLOUDWATCH_KMS_KEY_ALIAS" {

  type = string
}

variable "SECRETS_MANAGER_KMS_KEY_ALIAS" {

  type = string
}

variable "TAGS" {

  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources"
}

variable "GLUE_SCRIPTS_BUCKET_NAME" {

  type = string
}

variable "EBS_KMS_KEY_ALIAS" {

  type = string
}
