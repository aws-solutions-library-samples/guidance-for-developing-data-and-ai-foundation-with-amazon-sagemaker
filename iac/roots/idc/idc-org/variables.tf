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

variable "GROUPS" {

  type = list(string)
}

variable "USERS" { 

  type = map(object({
    email         = string
    given_name    = string
    family_name   = string
    groups        = list(string)
  }))
}

variable "PERMISSION_SETS" { 
  
  type = map(object({
    name              = string
    description       = string
    session_duration  = string
    policies          = list(string)
  }))
}

variable "SSM_KMS_KEY_ALIAS" {
  type = string
}

variable "LAMBDA_BUCKET" {
  description = "S3 bucket name for Lambda zip"
}

variable "LAMBDA_KEY" {
  description = "S3 key (path) to the zip file"
  default     = "lambda/instance_creation"
}
