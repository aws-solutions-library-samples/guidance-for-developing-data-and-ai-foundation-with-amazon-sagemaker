// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

terraform {
  required_version = ">= 1.8.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    # Generates the demo user's temporary password, see cognito.tf
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    # Used to space out AgentCore Memory strategy creation, see memory.tf
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}

provider "aws" {
  region = var.AWS_PRIMARY_REGION
}
