// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_kms_key" "ebs_kms_key" {

  key_id = "alias/${var.EBS_KMS_KEY_ALIAS}"
}

data "aws_kms_key" "secrets_manager_kms_key" {

  key_id = "alias/${var.SECRETS_MANAGER_KMS_KEY_ALIAS}"
}

// Splunk EC2 Role
resource "aws_iam_role" "splunk_role" {

  name = "${var.APP}-${var.ENV}-splunk-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "splunk-role"
  }
}

# Allow SSH access from Systems Manager
resource "aws_iam_role_policy_attachment" "splunk_ssm" {

  role       = aws_iam_role.splunk_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Add Secrets Manager access policy
resource "aws_iam_role_policy" "secrets_manager_access" {

  name = "${var.APP}-${var.ENV}-secrets-manager-policy"
  role = aws_iam_role.splunk_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ]
        Resource = [
          "*"
        ]
        Condition = {
          StringEquals = {
            "secretsmanager:ResourceTag/Usage" : "splunk"
          }
        }
      },
    ]
  })
}

# Add KMS access policy
resource "aws_iam_role_policy" "kms_access" {

  name = "${var.APP}-${var.ENV}-kms-policy"
  role = aws_iam_role.splunk_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = [
          data.aws_kms_key.secrets_manager_kms_key.arn,
          data.aws_kms_key.ebs_kms_key.arn
        ]
      }
    ]
  })
}

# Create instance profile
resource "aws_iam_instance_profile" "splunk_profile" {

  name = "${var.APP}-${var.ENV}-splunk-profile"
  role = aws_iam_role.splunk_role.name
}

// Glue Role
resource "aws_iam_role" "aws_iam_glue_role" {

  name = "${var.APP}-${var.ENV}-glue-role"

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "glue"
  }

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "glue.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "glue_glue_service_attachment" {

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
  role       = aws_iam_role.aws_iam_glue_role.id
}

resource "aws_iam_role_policy_attachment" "glue_s3_tables_full_access_attachment" {

  policy_arn = "arn:aws:iam::aws:policy/AmazonS3TablesFullAccess"
  role       = aws_iam_role.aws_iam_glue_role.id
}

resource "aws_iam_role_policy_attachment" "glue_s3_full_access_attachment" {

  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.aws_iam_glue_role.id
}

resource "aws_iam_role_policy" "glue_policy" {

  name = "${var.APP}-${var.ENV}-glue-policy"
  role = aws_iam_role.aws_iam_glue_role.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.APP}-${var.ENV}-billing-data-primary/*",
          "arn:aws:s3:::${var.APP}-${var.ENV}-inventory-data-source-primary/*",
          "arn:aws:s3:::${var.APP}-${var.ENV}-inventory-data-destination-primary/*",
          "arn:aws:s3:::${var.APP}-${var.ENV}-billing-iceberg-primary/*",
          "arn:aws:s3:::${var.APP}-${var.ENV}-inventory-iceberg-primary/*",
          "arn:aws:s3:::${var.APP}-${var.ENV}-billing-hive-primary/*",
          "arn:aws:s3:::${var.APP}-${var.ENV}-inventory-hive-primary/*",
          "arn:aws:s3:::${var.APP}-${var.ENV}-splunk-iceberg-primary/*",
          "arn:aws:s3:::${var.APP}-${var.ENV}-price-data-primary/*",
          "arn:aws:s3:::${var.APP}-${var.ENV}-price-hive-primary/*",
          "arn:aws:s3:::${var.APP}-${var.ENV}-price-iceberg-primary/*",
          "arn:aws:s3:::${var.APP}-${var.ENV}-glue-scripts-primary/*",
          "arn:aws:s3:::${var.APP}-${var.ENV}-glue-dependencies-primary/*",
          "arn:aws:s3:::${var.APP}-${var.ENV}-glue-jars-primary/*",
          "arn:aws:s3:::${var.APP}-${var.ENV}-glue-spark-logs-primary/*",
          "arn:aws:s3:::${var.APP}-${var.ENV}-glue-temp-primary/*",
          "arn:aws:s3:::${var.APP}-${var.ENV}-athena-output-primary/*",
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:AssociateKmsKey",
        ],
        "Resource" : "arn:aws:logs:${var.AWS_PRIMARY_REGION}:${local.account_id}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Resource = ["arn:aws:kms:${var.AWS_PRIMARY_REGION}:${local.account_id}:*"]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "*"
        ]
        Condition = {
          StringEquals = {
            "secretsmanager:ResourceTag/Usage" : [
              "splunk",
              "snowflake"
            ]
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "s3tables:CreateTableBucket",
          "s3tables:GetTableBucket",
          "s3tables:ListTableBuckets",
          "s3tables:CreateNamespace",
          "s3tables:ListNamespace",
          "s3tables:GetNamespace",
          "s3tables:DeleteNamespace",
          "s3tables:GetTableMetadataLocation",
          "s3tables:UpdateTableMetadataLocation",
          "s3tables:DeleteTableBucket",
          "s3tables:CreateTable",
          "s3tables:GetTable",
          "s3tables:ListTables",
          "s3tables:RenameTable",
          "s3tables:GetTableData",
          "s3tables:PutTableData",
          "s3tables:*",
        ]
        Resource = "arn:aws:s3tables:${local.region}:${local.account_id}:bucket/*"
      },
      {
        Effect = "Allow"
        Action = [
          "lakeformation:GetDataAccess",
          "lakeformation:GetTemporaryGlueTableCredentials",
          "lakeformation:GetTemporaryGluePartitionCredentials"
        ]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "datazone:postLineageEvent",
          "datazone:postTimeSeriesDataPoints",
          "datazone:SearchListings"
        ]
        Resource = ["*"]
      },
      {
        Effect = "Allow",
        Action = [
          "cloudtrail:LookupEvents"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "lakeformation:*"
        ],
        Resource = "*"
      },
      {
        Action = [
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeCluster",
          "kafka-cluster:AlterCluster",
          "kafka-cluster:*Topic*",
          "kafka-cluster:WriteData",
          "kafka-cluster:ReadData",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:AlterGroup",
          "kafka-cluster:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "kafka:DescribeCluster",
          "kafka:GetBootstrapBrokers",
          "kafka:ListClusters",
          "kafka:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kafka:DescribeCluster",
          "kafka:GetBootstrapBrokers",
          "kafka:ListClusters"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:Connect",
          "kafka-cluster:AlterCluster",
          "kafka-cluster:DescribeCluster"
        ]
        Resource = "arn:aws:kafka:${var.AWS_PRIMARY_REGION}:${data.aws_caller_identity.current.account_id}:cluster/${var.APP}-${var.ENV}-msk-cluster/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:*Topic*",
          "kafka-cluster:WriteData",
          "kafka-cluster:ReadData"
        ]
        Resource = "arn:aws:kafka:${var.AWS_PRIMARY_REGION}:${data.aws_caller_identity.current.account_id}:topic/${var.APP}-${var.ENV}-msk-cluster/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:DescribeGroup"
        ]
        Resource = "arn:aws:kafka:${var.AWS_PRIMARY_REGION}:${data.aws_caller_identity.current.account_id}:group/${var.APP}-${var.ENV}-msk-cluster/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = [
          "arn:aws:ssm:${var.AWS_PRIMARY_REGION}:${data.aws_caller_identity.current.account_id}:parameter/${var.APP}/${var.ENV}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.AWS_PRIMARY_REGION}:${data.aws_caller_identity.current.account_id}:secret:${var.APP}-${var.ENV}-msk-endpoint*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "event_bridge_role" {

  name = "${var.APP}-${var.ENV}-event-bridge-role"

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "event bridge"
  }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "events.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "event_bridge_policy_attachment" {

  role       = aws_iam_role.event_bridge_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}

// Sagemaker Role
resource "aws_iam_role" "sagemaker_role" {

  name = "${var.APP}-${var.ENV}-sagemaker-role"

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "sagemaker"
  }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "sagemaker.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sagemaker_policy_attachment_1" {

  role       = aws_iam_role.sagemaker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_iam_role_policy_attachment" "sagemaker_policy_attachment_2" {

  role       = aws_iam_role.sagemaker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerCanvasAIServicesAccess"
}

resource "aws_iam_role_policy_attachment" "sagemaker_policy_attachment_3" {

  role       = aws_iam_role.sagemaker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerCanvasDataPrepFullAccess"
}

resource "aws_iam_role_policy_attachment" "sagemaker_policy_attachment_4" {

  role       = aws_iam_role.sagemaker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerCanvasFullAccess"
}

resource "aws_iam_role_policy_attachment" "sagemaker_policy_attachment_5" {

  role       = aws_iam_role.sagemaker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_policy" "sagemaker_policy" {

  name        = "${var.APP}-${var.ENV}-sagemaker-policy"
  path        = "/"
  description = "${var.APP}-${var.ENV}-sagemaker-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "arn:aws:kms:${var.AWS_PRIMARY_REGION}:${local.account_id}:*"
      }
    ]
  })

  #checkov:skip=CKV_AWS_288: "Ensure IAM policies does not allow data exfiltration": "Skipping this for simplicity"
  #checkov:skip=CKV_AWS_289: "Ensure IAM policies does not allow permissions management / resource exposure without constraints": "Skipping this for simplicity"
  #checkov:skip=CKV_AWS_290: "Ensure IAM policies does not allow write access without constraints": "Skipping this for simplicity"
}

resource "aws_iam_role_policy_attachment" "sagemaker_custom_policy_attachment" {

  role       = aws_iam_role.sagemaker_role.name
  policy_arn = aws_iam_policy.sagemaker_policy.arn
}

# Lake Formation Service Role
resource "aws_iam_role" "lakeformation_service_role" {

  name = "${var.APP}-${var.ENV}-lakeformation-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "LakeFormationDataAccessPolicy"
        Effect = "Allow"
        Action = ["sts:AssumeRole",
          "sts:SetContext",
        "sts:SetSourceIdentity"]
        Principal = {
          Service = [
            "lakeformation.amazonaws.com",
            "glue.amazonaws.com",
            "athena.amazonaws.com"
          ]
        }
      }
    ]
  })
}

# Lake Formation Service Role Policy
resource "aws_iam_role_policy" "lakeformation_service_role_policy" {

  name = "${var.APP}-${var.ENV}-lakeformation-service-role-policy"
  role = aws_iam_role.lakeformation_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "LakeFormationServiceRole"
        Effect = "Allow"
        Action = [
          "s3tables:ListTableBuckets",
          "s3tables:CreateTableBucket",
          "s3tables:GetTableBucket",
          "s3tables:CreateNamespace",
          "s3tables:GetNamespace",
          "s3tables:ListNamespaces",
          "s3tables:DeleteNamespace",
          "s3tables:DeleteTableBucket",
          "s3tables:CreateTable",
          "s3tables:DeleteTable",
          "s3tables:GetTable",
          "s3tables:ListTables",
          "s3tables:RenameTable",
          "s3tables:UpdateTableMetadataLocation",
          "s3tables:GetTableMetadataLocation",
          "s3tables:GetTableData",
          "s3tables:PutTableData",
          "glue:CreateDatabase",
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:CreateTable",
          "glue:GetTable",
          "glue:GetTables",
          "lakeformation:RegisterResource",
          "lakeformation:GetDataLakeSettings",
          "lakeformation:PutDataLakeSettings",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource : [
          "arn:aws:s3tables:${local.region}:${local.account_id}:bucket/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Resource = ["arn:aws:kms:${var.AWS_PRIMARY_REGION}:${local.account_id}:*"]
      }
    ]
  })
}

# EventBridge Role
resource "aws_iam_role" "eventbridge_role" {
  name = "${var.APP}-${var.ENV}-eventbridge-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

// EventBridge Policy
resource "aws_iam_policy" "glue_start_policy" {

  name        = "${var.APP}-${var.ENV}-glue-start-policy"
  description = "Allow EventBridge to start Glue jobs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:NotifyEvent",
          "glue:StartJobRun",
          "glue:StartWorkflowRun",
          "glue:GetWorkflow"
        ]
        Resource = [
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:partition/*",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/*",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/*/*"
        ]
      }
    ]
  })

  #checkov:skip=CKV_AWS_290: "Ensure IAM policies does not allow write access without constraints": "Skipping this for simplicity"
}

resource "aws_iam_role_policy_attachment" "glue_policy_attach" {

  role       = aws_iam_role.eventbridge_role.name
  policy_arn = aws_iam_policy.glue_start_policy.arn
}

resource "aws_iam_role" "domain_execution_role" {

  name = "${var.APP}-${var.ENV}-datazone-domain-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRole", "sts:TagSession"]
        Effect = "Allow"
        Principal = {
          Service = "datazone.amazonaws.com"
        }
      },
      {
        Action = ["sts:AssumeRole", "sts:TagSession"]
        Effect = "Allow"
        Principal = {
          Service = "cloudformation.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "domain_execution_policy_datazone" {

  name = "${var.APP}-${var.ENV}-datazone-domain-execution-policy-datazone"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "datazone:ListEnvironmentBlueprintConfigurationSummaries",
          "datazone:ListEnvironmentBlueprintConfigurations",
          "datazone:DeleteEnvironmentBlueprint",
          "datazone:RejectSubscriptionRequest",
          "datazone:AcceptPredictions",
          "datazone:AddPolicyGrant",
          "datazone:UpdateEnvironment",
          "datazone:RefreshToken",
          "datazone:UpdateRule",
          "datazone:DeleteProjectMembership",
          "datazone:ListProjectMemberships",
          "datazone:GetEnvironmentCredentials",
          "datazone:UpdateProject",
          "datazone:ListEnvironments",
          "datazone:GetEnvironmentActionLink",
          "datazone:CreateDomain",
          "datazone:DeleteProject",
          "datazone:DeleteListing",
          "datazone:CreateDataSource",
          "datazone:UpdateEnvironmentAction",
          "datazone:CreateDomainUnit",
          "datazone:ListDataProductRevisions",
          "datazone:GetSubscriptionTarget",
          "datazone:ListLinkedTypes",
          "datazone:DeleteSubscriptionGrant",
          "datazone:DeleteEnvironmentProfile",
          "datazone:CreateFormType",
          "datazone:ListSubscriptionGrants",
          "datazone:GetEnvironmentBlueprintConfiguration",
          "datazone:ListDomainUnitsForParent",
          "datazone:ValidatePassRole",
          "datazone:DeleteFormType",
          "datazone:UpdateEnvironmentProfile",
          "datazone:ListDataSources",
          "datazone:ListMetadataGenerationRuns",
          "datazone:AssociateEnvironmentRole",
          "datazone:DeleteEnvironmentAction",
          "datazone:DeleteEnvironment",
          "datazone:ListDataSourceRuns",
          "datazone:ListAssetFilters",
          "datazone:CreateAssetType",
          "datazone:CreateSubscriptionGrant",
          "datazone:ProvisionDomain",
          "datazone:CreateEnvironmentBlueprint",
          "datazone:AcceptSubscriptionRequest",
          "datazone:GetSubscriptionGrant",
          "datazone:CancelSubscription",
          "datazone:ListSubscriptionRequests",
          "datazone:ListSubscriptions",
          "datazone:PutEnvironmentBlueprintConfiguration",
          "datazone:CreateListingChangeSet",
          "datazone:ListEntityOwners",
          "datazone:GetGlossary",
          "datazone:ListProjectProfiles",
          "datazone:GetProjectProfile",
          "datazone:SsoLogout",
          "datazone:CancelMetadataGenerationRun",
          "datazone:GetRule",
          "datazone:SearchGroupProfiles",
          "datazone:SearchRules",
          "datazone:DeleteGlossary",
          "datazone:PostLineageEvent",
          "datazone:ListPolicyGrants",
          "datazone:DeleteEnvironmentBlueprintConfiguration",
          "datazone:GetGlossaryTerm",
          "datazone:CreateEnvironment",
          "datazone:DeleteConnection",
          "datazone:RemovePolicyGrant",
          "datazone:Search",
          "datazone:UpdateUserProfile",
          "datazone:ListDataSourceRunActivities",
          "datazone:GetDomainUnit",
          "datazone:DeleteProjectProfile",
          "datazone:CreateProjectProfile",
          "datazone:RevokeSubscription",
          "datazone:GetListing",
          "datazone:CreateAsset",
          "datazone:ListEnvironmentProfiles",
          "datazone:GetUpdateEligibility",
          "datazone:GetAssetFilter",
          "datazone:GetDataSource",
          "datazone:CreateSubscriptionTarget",
          "datazone:ListWarehouseMetadata",
          "datazone:GetEnvironmentAction",
          "datazone:CreateDataProductRevision",
          "datazone:GetEnvironmentProfile",
          "datazone:DeleteSubscriptionRequest",
          "datazone:RejectPredictions",
          "datazone:CreateUserProfile",
          "datazone:DeleteTimeSeriesDataPoints",
          "datazone:StopMetadataGenerationRun",
          "datazone:CreateEnvironmentAction",
          "datazone:CreateEnvironmentProfile",
          "datazone:UpdateGroupProfile",
          "datazone:CreateGroupProfile",
          "datazone:GetMetadataGenerationRun",
          "datazone:ListGroupsForUser",
          "datazone:UpdateEnvironmentDeploymentStatus",
          "datazone:GetAssetType",
          "datazone:UpdateEnvironmentBlueprint",
          "datazone:ListJobRuns",
          "datazone:SearchListings",
          "datazone:ListAccountEnvironments",
          "datazone:PostTimeSeriesDataPoints",
          "datazone:GetProject",
          "datazone:DeleteDataProduct",
          "datazone:CreateGlossaryTerm",
          "datazone:ListSubscriptionTargets",
          "datazone:ListLineageNodeHistory",
          "datazone:SearchTypes",
          "datazone:UpdateDomain",
          "datazone:GetGroupProfile",
          "datazone:UpdateSubscriptionTarget",
          "datazone:ListEnvironmentActions",
          "datazone:ListAssetRevisions",
          "datazone:CreateGlossary",
          "datazone:RemoveEntityOwner",
          "datazone:UpdateSubscriptionGrantStatus",
          "datazone:GetAsset",
          "datazone:GetSubscriptionRequestDetails",
          "datazone:GetDataProduct",
          "datazone:GetLineageNode",
          "datazone:GetDomain",
          "datazone:CreateRule",
          "datazone:CreateDataProduct",
          "datazone:CreateAssetRevision",
          "datazone:StartDataSourceRun",
          "datazone:UpdateSubscriptionRequest",
          "datazone:ListRules",
          "datazone:UpdateConnection",
          "datazone:UpdateGlossaryTerm",
          "datazone:DeleteAssetFilter",
          "datazone:SearchUserProfiles",
          "datazone:GetSubscriptionEligibility",
          "datazone:GetJobRun",
          "datazone:ListTimeSeriesDataPoints",
          "datazone:ListDomains",
          "datazone:ListTagsForResource",
          "datazone:AddEntityOwner",
          "datazone:CreateAssetFilter",
          "datazone:BatchPutLinkedTypes",
          "datazone:DeleteAsset",
          "datazone:DeleteDomain",
          "datazone:GetDataSourceRun",
          "datazone:UpdateEnvironmentConfiguration",
          "datazone:DeleteDomainUnit",
          "datazone:DeleteGlossaryTerm",
          "datazone:DeleteDataSource",
          "datazone:DeleteAssetType",
          "datazone:UpdateDataSource",
          "datazone:GetLineageEvent",
          "datazone:SsoLogin",
          "datazone:UpdateDomainUnit",
          "datazone:GetSubscription",
          "datazone:UpdateDataSourceRunActivities",
          "datazone:GetUserProfile",
          "datazone:StartMetadataGenerationRun",
          "datazone:ListEnvironmentBlueprints",
          "datazone:CreateProjectMembership",
          "datazone:UpdateAssetFilter",
          "datazone:GetEnvironmentBlueprint",
          "datazone:ListLineageEvents",
          "datazone:ListProjects",
          "datazone:BatchDeleteLinkedTypes",
          "datazone:DisassociateEnvironmentRole",
          "datazone:CreateProject",
          "datazone:UpdateProjectProfile",
          "datazone:ListNotifications",
          "datazone:GetFormType",
          "datazone:ListConnections",
          "datazone:GetTimeSeriesDataPoint",
          "datazone:DeleteRule",
          "datazone:GetConnection",
          "datazone:GetDomainSharingPolicy",
          "datazone:UpdateGlossary",
          "datazone:CreateSubscriptionRequest",
          "datazone:DeleteSubscriptionTarget",
          "datazone:CreateConnection",
          "datazone:GetDomainExecutionRoleCredentials",
          "datazone:GetEnvironment"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })

  #checkov:skip=CKV_AWS_288: "Ensure IAM policies does not allow data exfiltration": "Skipping this for simplicity"
  #checkov:skip=CKV_AWS_289: "Ensure IAM policies does not allow permissions management / resource exposure without constraints": "Skipping this for simplicity"
  #checkov:skip=CKV_AWS_290: "Ensure IAM policies does not allow write access without constraints": "Skipping this for simplicity"
  #checkov:skip=CKV_AWS_355: "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions": "Skipping this for simplicity"
}

resource "aws_iam_policy" "domain_execution_policy_ram" {

  name = "${var.APP}-${var.ENV}-datazone-domain-execution-policy-ram"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ram:AcceptResourceShareInvitation",
          "ram:ListPermissionVersions",
          "ram:GetResourcePolicies",
          "ram:GetResourceShareInvitations",
          "ram:GetPermission",
          "ram:GetResourceShares",
          "ram:CreatePermission",
          "ram:ListResourceTypes",
          "ram:DeletePermissionVersion",
          "ram:PromoteResourceShareCreatedFromPolicy",
          "ram:ReplacePermissionAssociations",
          "ram:SetDefaultPermissionVersion",
          "ram:DeleteResourceShare",
          "ram:DisassociateResourceShare",
          "ram:DisassociateResourceSharePermission",
          "ram:ListReplacePermissionAssociationsWork",
          "ram:GetResourceShareAssociations",
          "ram:CreatePermissionVersion",
          "ram:DeletePermission",
          "ram:AssociateResourceSharePermission",
          "ram:ListResources",
          "ram:ListResourceSharePermissions",
          "ram:PromotePermissionCreatedFromPolicy",
          "ram:ListPermissions",
          "ram:ListPermissionAssociations",
          "ram:RejectResourceShareInvitation",
          "ram:ListPrincipals",
          "ram:ListPendingInvitationResources",
          "ram:AssociateResourceShare",
          "ram:CreateResourceShare",
          "ram:UpdateResourceShare"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })

  #checkov:skip=CKV_AWS_288: "Ensure IAM policies does not allow data exfiltration": "Skipping this for simplicity"
  #checkov:skip=CKV_AWS_289: "Ensure IAM policies does not allow permissions management / resource exposure without constraints": "Skipping this for simplicity"
  #checkov:skip=CKV_AWS_290: "Ensure IAM policies does not allow write access without constraints": "Skipping this for simplicity"
  #checkov:skip=CKV_AWS_355: "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions": "Skipping this for simplicity"
}

resource "aws_iam_policy" "domain_execution_policy_sso" {

  name = "${var.APP}-${var.ENV}-datazone-domain-execution-policy-sso"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sso:DeleteProfile",
          "sso:CreateAccountAssignment",
          "sso:ListCustomerManagedPolicyReferencesInPermissionSet",
          "sso:CreateManagedApplicationInstance",
          "sso:UpdateApplicationInstanceResponseConfiguration",
          "sso:CreatePermissionSet",
          "sso:CreateTrustedTokenIssuer",
          "sso:CreateTrust",
          "sso:SearchGroups",
          "sso:ListInstances",
          "sso:ListApplicationAccessScopes",
          "sso:ListProfileAssociations",
          "sso:ListAccountAssignmentDeletionStatus",
          "sso:CreateApplicationInstance",
          "sso:DescribeInstance",
          "sso:DeleteAccountAssignment",
          "sso:AssociateProfile",
          "sso:UpdateApplication",
          "sso:GetInlinePolicyForPermissionSet",
          "sso:ListManagedPoliciesInPermissionSet",
          "sso:CreateApplication",
          "sso:DescribePermissionSetProvisioningStatus",
          "sso:GetTrust",
          "sso:ListApplicationGrants",
          "sso:StartSSO",
          "sso:ListTrustedTokenIssuers",
          "sso:UpdateTrustedTokenIssuer",
          "sso:AssociateDirectory",
          "sso:DeleteApplication",
          "sso:UpdateApplicationInstanceSecurityConfiguration",
          "sso:GetPermissionSet",
          "sso:ListApplicationInstances",
          "sso:DeleteApplicationGrant",
          "sso:PutApplicationAuthenticationMethod",
          "sso:DescribePermissionSet",
          "sso:GetProfile",
          "sso:DeleteApplicationAssignment",
          "sso:ListApplicationProviders",
          "sso:ListDirectoryAssociations",
          "sso:ListPermissionSets",
          "sso:GetApplicationTemplate",
          "sso:ListPermissionSetsProvisionedToAccount",
          "sso:PutApplicationAssignmentConfiguration",
          "sso:DeleteManagedApplicationInstance",
          "sso:GetPermissionsPolicy",
          "sso:UpdateApplicationInstanceStatus",
          "sso:PutApplicationGrant",
          "sso:PutInlinePolicyToPermissionSet",
          "sso:GetSsoConfiguration",
          "sso:GetPermissionsBoundaryForPermissionSet",
          "sso:GetApplicationInstance",
          "sso:UpdateProfile",
          "sso:UpdateInstance",
          "sso:CreateApplicationInstanceCertificate",
          "sso:ListAccountAssignmentCreationStatus",
          "sso:CreateInstanceAccessControlAttributeConfiguration",
          "sso:ListApplicationAuthenticationMethods",
          "sso:ListAccountsForProvisionedPermissionSet",
          "sso:DescribeTrustedTokenIssuer",
          "sso:DeleteApplicationInstanceCertificate",
          "sso:DescribeApplicationProvider",
          "sso:ListAccountAssignmentsForPrincipal",
          "sso:ListTagsForResource",
          "sso:DeleteInlinePolicyFromPermissionSet",
          "sso:DeleteInstance",
          "sso:DescribeRegisteredRegions",
          "sso:GetApplicationGrant",
          "sso:DeletePermissionSet",
          "sso:PutApplicationAccessScope",
          "sso:CreateProfile",
          "sso:DeleteInstanceAccessControlAttributeConfiguration",
          "sso:ListPermissionSetProvisioningStatus",
          "sso:UpdateApplicationInstanceActiveCertificate",
          "sso:GetApplicationAuthenticationMethod",
          "sso:DescribeAccountAssignmentDeletionStatus",
          "sso:ListApplicationAssignmentsForPrincipal",
          "sso:ProvisionPermissionSet",
          "sso:DescribeApplication",
          "sso:DescribeAccountAssignmentCreationStatus",
          "sso:UpdateInstanceAccessControlAttributeConfiguration",
          "sso:DeleteTrustedTokenIssuer",
          "sso:ListAccountAssignments",
          "sso:DescribeDirectories",
          "sso:GetApplicationAccessScope",
          "sso:ListApplicationTemplates",
          "sso:CreateInstance",
          "sso:GetApplicationAssignmentConfiguration",
          "sso:DescribeApplicationAssignment",
          "sso:DeleteApplicationInstance",
          "sso:DescribePermissionsPolicies",
          "sso:ImportApplicationInstanceServiceProviderMetadata",
          "sso:UpdateApplicationInstanceDisplayData",
          "sso:DescribeInstanceAccessControlAttributeConfiguration",
          "sso:GetManagedApplicationInstance",
          "sso:UpdateManagedApplicationInstanceStatus",
          "sso:ListProfiles",
          "sso:GetSharedSsoConfiguration",
          "sso:SearchUsers",
          "sso:DisassociateDirectory",
          "sso:DisassociateProfile",
          "sso:DeleteApplicationAccessScope",
          "sso:UpdateDirectoryAssociation",
          "sso:UpdateSSOConfiguration",
          "sso:GetMfaDeviceManagementForDirectory",
          "sso:PutMfaDeviceManagementForDirectory",
          "sso:ListApplications",
          "sso:UpdateApplicationInstanceServiceProviderConfiguration",
          "sso:UpdateTrust",
          "sso:CreateApplicationAssignment",
          "sso:DeleteApplicationAuthenticationMethod",
          "sso:UpdateApplicationInstanceResponseSchemaConfiguration",
          "sso:ListApplicationAssignments",
          "sso:DescribeTrusts",
          "sso:ListApplicationInstanceCertificates",
          "sso:GetSSOStatus"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })

  #checkov:skip=CKV_AWS_288: "Ensure IAM policies does not allow data exfiltration": "Skipping this for simplicity"
  #checkov:skip=CKV_AWS_289: "Ensure IAM policies does not allow permissions management / resource exposure without constraints": "Skipping this for simplicity"
  #checkov:skip=CKV_AWS_290: "Ensure IAM policies does not allow write access without constraints": "Skipping this for simplicity"
  #checkov:skip=CKV_AWS_355: "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions": "Skipping this for simplicity"
}

resource "aws_iam_policy" "domain_execution_policy_kms" {

  name = "${var.APP}-${var.ENV}-datazone-domain-execution-policy-kms"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kms:GetPublicKey",
          "kms:Decrypt",
          "kms:ListKeyPolicies",
          "kms:GenerateRandom",
          "kms:ListKeyRotations",
          "kms:ListRetirableGrants",
          "kms:GetKeyPolicy",
          "kms:ListResourceTags",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyPairWithoutPlaintext",
          "kms:GenerateDataKeyPair",
          "kms:ListGrants",
          "kms:GetParametersForImport",
          "kms:DescribeCustomKeyStores",
          "kms:ListKeys",
          "kms:Encrypt",
          "kms:GetKeyRotationStatus",
          "kms:ListAliases",
          "kms:RevokeGrant",
          "kms:ReEncryptTo",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })

  #checkov:skip=CKV_AWS_288: "Ensure IAM policies does not allow data exfiltration": "Skipping this for simplicity"
  #checkov:skip=CKV_AWS_289: "Ensure IAM policies does not allow permissions management / resource exposure without constraints": "Skipping this for simplicity"
  #checkov:skip=CKV_AWS_290: "Ensure IAM policies does not allow write access without constraints": "Skipping this for simplicity"
  #checkov:skip=CKV_AWS_355: "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions": "Skipping this for simplicity"
}

resource "aws_iam_role_policy_attachment" "domain_execution_policy_attachment_datazone" {

  role       = aws_iam_role.domain_execution_role.name
  policy_arn = aws_iam_policy.domain_execution_policy_datazone.arn
}

resource "aws_iam_role_policy_attachment" "domain_execution_policy_attachment_ram" {

  role       = aws_iam_role.domain_execution_role.name
  policy_arn = aws_iam_policy.domain_execution_policy_ram.arn
}

resource "aws_iam_role_policy_attachment" "domain_execution_policy_attachment_sso" {

  role       = aws_iam_role.domain_execution_role.name
  policy_arn = aws_iam_policy.domain_execution_policy_sso.arn
}

resource "aws_iam_role_policy_attachment" "domain_execution_policy_attachment_kms" {

  role       = aws_iam_role.domain_execution_role.name
  policy_arn = aws_iam_policy.domain_execution_policy_kms.arn
}

resource "aws_iam_role" "lambda_billing_trigger_role" {
  name = "${var.APP}-${var.ENV}-lambda-billing-trigger-role"

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "billing"
  }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role" "lambda_inventory_trigger_role" {
  name = "${var.APP}-${var.ENV}-lambda-inventory-trigger-role"

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "inventory"
  }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_billing_basic_execution" {

  role       = aws_iam_role.lambda_billing_trigger_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_inventory_basic_execution" {

  role       = aws_iam_role.lambda_inventory_trigger_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_billing_glue_workflow_policy" {

  name = "${var.APP}-${var.ENV}-lambda-billing-glue-policy"
  role = aws_iam_role.lambda_billing_trigger_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:StartWorkflowRun",
          "glue:GetWorkflow",
          "glue:GetWorkflowRun",
          "glue:PutWorkflowRunProperties",
          "glue:GetWorkflowRunProperties"
        ]
        Resource = "arn:aws:glue:${var.AWS_PRIMARY_REGION}:${local.account_id}:workflow/${var.APP}-${var.ENV}-*"
      },
      {
        Effect = "Allow"
        Action = [
          "glue:UpdateCrawler",
          "glue:GetCrawler"
        ]
        Resource = "arn:aws:glue:${var.AWS_PRIMARY_REGION}:${local.account_id}:crawler/${var.APP}-${var.ENV}-*"
      },
      {
        Effect   = "Allow",
        Action   = "sns:Publish",
        Resource = "arn:aws:sns:${var.AWS_PRIMARY_REGION}:${local.account_id}:${var.APP}-${var.ENV}-billing-lambda-topic"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_inventory_glue_workflow_policy" {

  name = "${var.APP}-${var.ENV}-lambda-inventory-glue-policy"
  role = aws_iam_role.lambda_inventory_trigger_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:StartWorkflowRun",
          "glue:GetWorkflow",
          "glue:GetWorkflowRun",
          "glue:PutWorkflowRunProperties",
          "glue:GetWorkflowRunProperties"
        ]
        Resource = "arn:aws:glue:${var.AWS_PRIMARY_REGION}:${local.account_id}:workflow/${var.APP}-${var.ENV}-*"
      },
      {
        Effect = "Allow"
        Action = [
          "glue:UpdateCrawler",
          "glue:GetCrawler"
        ]
        Resource = "arn:aws:glue:${var.AWS_PRIMARY_REGION}:${local.account_id}:crawler/${var.APP}-${var.ENV}-*"
      },
      {
        Effect   = "Allow",
        Action   = "sns:Publish",
        Resource = "arn:aws:sns:${var.AWS_PRIMARY_REGION}:${local.account_id}:${var.APP}-${var.ENV}-inventory-lambda-topic"
      }
    ]
  })
}

resource "aws_iam_role" "quicksight_service_role" {

  name = "${var.APP}-${var.ENV}-quicksight-service-role"

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "quick sight"
  }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "quicksight.amazonaws.com",
            "athena.amazonaws.com",
            "s3.amazonaws.com",
            "glue.amazonaws.com",
            "lakeformation.amazonaws.com",
          ]
        }
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "quicksight_custom_service_policy" {

  name = "quicksight-access-service-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : "iam:PassRole",
        "Resource" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.quicksight_service_role.name}"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:ListBucketMultipartUploads",
          "s3:ListMultipartUploadParts",
          "s3:PutObject",
          "s3:AbortMultipartUpload"
        ],
        "Resource" : [
          "arn:aws:s3:::aws-athena-query-results-*",
          "arn:aws:s3tables:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:bucket/*",
          "arn:aws:s3:::${var.APP}-${var.ENV}-athena-output-for-primary-workgroup-only",
          "arn:aws:s3:::${var.APP}-${var.ENV}-athena-output-for-primary-workgroup-only/*",
          "arn:aws:s3:::${var.APP}-${var.ENV}-athena-output-primary",
          "arn:aws:s3:::${var.APP}-${var.ENV}-athena-output-primary/*",
          "arn:aws:s3:::${var.APP}-${var.ENV}-glue-*",
          "arn:aws:s3:::${var.APP}-${var.ENV}-iceberg-*",
          "arn:aws:s3:::${var.APP}-${var.ENV}-inventory-*",
          "arn:aws:s3:::${var.APP}-${var.ENV}-billing-*",
          "arn:aws:s3:::${var.APP}-${var.ENV}-price-*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:AssociateKmsKey",
        ],
        "Resource" : "arn:aws:logs:${var.AWS_PRIMARY_REGION}:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Resource = [
          "arn:aws:kms:${var.AWS_PRIMARY_REGION}:${data.aws_caller_identity.current.account_id}:*",
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "athena:BatchGetQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "athena:GetWorkGroup",
          "athena:StartQueryExecution",
          "athena:StopQueryExecution",
          "athena:ListQueryExecutions",
          "athena:GetDataCatalog",
          "athena:GetDatabase",
          "athena:GetTableMetadata",
          "athena:ListDatabases",
          "athena:ListTableMetadata",
          "athena:ListWorkGroups",
          "athena:ListDataCatalogs",
          "athena:ListEngineVersions",
          "athena:GetView",
          "athena:ListViews",
          "athena:GetNamedQuery",
          "athena:ListNamedQueries",
          "athena:CreateNamedQuery",
          "athena:DeleteNamedQuery"
        ]
        Resource = [
          "arn:aws:athena:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:workgroup/*",
          "arn:aws:athena:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:datacatalog/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetPartitions",
          "glue:GetPartition",
          "glue:GetCatalogImportStatus"
        ]
        Resource = [
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:partition/*",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/*",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/*/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "lakeformation:GetDataAccess",
          "lakeformation:GrantPermissions",
          "lakeformation:DescribeResource",
          "lakeformation:ListPermissions",
          "lakeformation:BatchGrantPermissions"
        ]
        Resource = [
          "arn:aws:lakeformation:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog:*",
          "arn:aws:lakeformation:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/*",
          "arn:aws:lakeformation:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/*/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "lakeformation:GetResourceLFTags",
          "lakeformation:ListLFTags",
          "lakeformation:GetLFTag"
        ]
        Resource = "arn:aws:lakeformation:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:tag/*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "quicksight_custom_policy_attach" {
  role       = aws_iam_role.quicksight_service_role.name
  policy_arn = aws_iam_policy.quicksight_custom_service_policy.arn
}

resource "aws_iam_role_policy_attachment" "quicksight_managed_athena_access" {
  role       = aws_iam_role.quicksight_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSQuicksightAthenaAccess"
}

resource "aws_iam_role_policy_attachment" "quicksight_athena_full_access" {
  role       = aws_iam_role.quicksight_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonAthenaFullAccess"
}

resource "aws_iam_role_policy_attachment" "quicksight_glue_full_access" {
  role       = aws_iam_role.quicksight_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "quicksight_lf_data_permissions" {
  role       = aws_iam_role.quicksight_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLakeFormationDataAdmin"
}

resource "aws_lakeformation_data_lake_settings" "cross_account_settings" {
  parameters = {
    CROSS_ACCOUNT_VERSION = "4"
  }
}

resource "aws_lakeformation_data_lake_settings" "quicksight_lf_permission" {
  admins = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.CURRENT_ROLE}",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.quicksight_service_role.name}"
  ]
}
