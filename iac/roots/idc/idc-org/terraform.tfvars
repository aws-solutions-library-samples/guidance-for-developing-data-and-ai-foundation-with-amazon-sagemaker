// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

APP                        = "###APP_NAME###"
ENV                        = "###ENV_NAME###"
AWS_PRIMARY_REGION         = "###AWS_PRIMARY_REGION###"
AWS_SECONDARY_REGION       = "###AWS_SECONDARY_REGION###"
SSM_KMS_KEY_ALIAS          = "###APP_NAME###-###ENV_NAME###-systems-manager-secret-key"
LAMBDA_BUCKET              = "###APP_NAME###-###ENV_NAME###-lambda-bucket"
PERMISSION_SETS = {
  "Admin" = {
    name             = "Admin"
    description      = "Full Admin permissions"
    session_duration = "PT12H"
    policies         = ["arn:aws:iam::aws:policy/AmazonDataZoneFullAccess", 
                        "arn:aws:iam::aws:policy/AdministratorAccess",
                        "arn:aws:iam::aws:policy/AWSLakeFormationDataAdmin"]
  }
  "Domain Owner" = {
    name             = "DomainOwner"
    description      = "Domain management access"
    session_duration = "PT12H"
    policies         = ["arn:aws:iam::aws:policy/AmazonDataZoneFullAccess", 
                        "arn:aws:iam::aws:policy/IAMReadOnlyAccess"]
  }
  "Project Owner" = {
    name             = "ProjectOwner"
    description      = "Project management access"
    session_duration = "PT12H"
    policies         = ["arn:aws:iam::aws:policy/AmazonDataZoneFullUserAccess", 
                        "arn:aws:iam::aws:policy/IAMReadOnlyAccess"]
  }
  "Project Contributor" = {
    name             = "ProjectContributor"
    description      = "Read-only project access"
    session_duration = "PT12H"
    policies         = ["arn:aws:iam::aws:policy/AmazonDataZoneFullUserAccess",
                        "arn:aws:iam::aws:policy/IAMReadOnlyAccess"]
  }
}
GROUPS = [
  "Admin", 
  "Domain Owner",
  "Project Owner", 
  "Project Contributor"
]
USERS = {
  "chris-bakony-admin" = {
    email         = "chris-bakony-admin@example.com"
    given_name    = "Chris"
    family_name   = "Bakony"
    groups        = ["Admin"]
  }
  "ann-chouvey-downer" = {
    email         = "ann-chouvey-downer@example.com"
    given_name    = "Ann"
    family_name   = "Chouvey"
    groups        = ["Domain Owner"]
  }
  "lois-lanikini-powner" = {
    email         = "lois-lanikini-powner@example.com"
    given_name    = "Lois"
    family_name   = "Lanikini"
    groups        = ["Project Owner"]
  }
  "ben-doverano-contributor" = {
    email         = "ben-doverano-contributor@example.com"
    given_name    = "Ben"
    family_name   = "Doverano"
    groups        = ["Project Contributor"]
  }
}
