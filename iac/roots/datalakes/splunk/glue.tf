// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_iam_role" "glue_role" {

  name = var.GLUE_ROLE_NAME
}

data "aws_kms_key" "glue_kms_key" {

  provider = aws.primary
  key_id   = "alias/${var.GLUE_KMS_KEY_ALIAS}"
}

data "aws_kms_key" "cloudwatch_kms_key" {

  provider = aws.primary
  key_id   = "alias/${var.CLOUDWATCH_KMS_KEY_ALIAS}"
}

data "aws_secretsmanager_secret_version" "splunk_creds" {

  secret_id = aws_secretsmanager_secret.splunk_credentials.id
  depends_on = [
    aws_secretsmanager_secret_version.splunk_credentials
  ]
}

locals {
  splunk_creds = jsondecode(data.aws_secretsmanager_secret_version.splunk_creds.secret_string)
}

resource "aws_glue_security_configuration" "glue_security_configuration_splunk" {

  name = "${var.APP}-${var.ENV}-glue-security-configuration-splunk"

  encryption_configuration {
    cloudwatch_encryption {
      cloudwatch_encryption_mode = "SSE-KMS"
      kms_key_arn                = data.aws_kms_key.cloudwatch_kms_key.arn
    }

    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = "CSE-KMS"
      kms_key_arn                   = data.aws_kms_key.glue_kms_key.arn
    }

    s3_encryption {
      s3_encryption_mode = "SSE-KMS"
      kms_key_arn        = data.aws_kms_key.glue_kms_key.arn
    }
  }
}

resource "aws_glue_data_catalog_encryption_settings" "encryption_setting-splunk" {

  data_catalog_encryption_settings {

    connection_password_encryption {
      aws_kms_key_id                       = data.aws_kms_key.glue_kms_key.arn
      return_connection_password_encrypted = true
    }

    encryption_at_rest {
      catalog_encryption_mode = "SSE-KMS"
      sse_aws_kms_key_id      = data.aws_kms_key.glue_kms_key.arn
    }
  }
}

data "aws_s3_bucket" "glue_scripts_bucket" {

  bucket = var.GLUE_SCRIPTS_BUCKET_NAME
}

resource "aws_s3_object" "splunk_glue_scripts" {

  for_each   = fileset("${path.module}/", "*.py")
  bucket     = data.aws_s3_bucket.glue_scripts_bucket.id
  key        = each.value
  source     = "${path.module}/${each.value}"
  kms_key_id = data.aws_kms_key.s3_primary_key.arn
}

# Glue Database
resource "aws_glue_catalog_database" "splunk_database" {

  name = "${var.APP}_${var.ENV}_splunk"

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "splunk"
  }
}

resource "aws_lakeformation_permissions" "database_permissions" {

  principal   = data.aws_iam_role.glue_role.arn
  permissions = ["DESCRIBE", "CREATE_TABLE", "ALTER", "DROP"]

  database {
    name = "${var.APP}_${var.ENV}_splunk"
  }

  depends_on = [aws_glue_catalog_database.splunk_database]
}

resource "aws_lakeformation_permissions" "tables_permissions" {

  principal   = data.aws_iam_role.glue_role.arn
  permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]

  table {
    database_name = "${var.APP}_${var.ENV}_splunk"
    wildcard      = true
  }

  depends_on = [aws_glue_catalog_database.splunk_database]
}

# Target Iceberg table with same schema
resource "aws_glue_catalog_table" "splunk_iceberg" {

  name          = "${var.APP}_${var.ENV}_splunk_iceberg"
  database_name = aws_glue_catalog_database.splunk_database.name
  table_type    = "EXTERNAL_TABLE"

  open_table_format_input {
    iceberg_input {
      metadata_operation = "CREATE"
    }
  }

  depends_on = [module.iceberg_splunk_bucket, 
                aws_lakeformation_permissions.iceberg_deployer_role,
                aws_lakeformation_permissions.iceberg_glue_role]

  storage_descriptor {
    location = var.SPLUNK_ICEBERG_BUCKET

    columns {
      name = "_time"
      type = "timestamp"
    }
    columns {
      name = "host"
      type = "string"
    }
    columns {
      name = "source"
      type = "string"
    }
    columns {
      name = "sourcetype"
      type = "string"
    }
  }
}

resource "aws_glue_connection" "splunk_vpc_connection" {

  name            = "${var.APP}-${var.ENV}-splunk-vpc-connection"
  connection_type = "NETWORK"

  physical_connection_requirements {
    availability_zone      = aws_instance.splunk.availability_zone
    security_group_id_list = [local.GLUE_SECURITY_GROUP]
    subnet_id              = local.PRIVATE_SUBNET1_ID
  }
}

# ETL Job
resource "aws_glue_job" "splunk_job" {

  name              = "${var.APP}-${var.ENV}-splunk-iceberg-static"
  description       = "${var.APP}-${var.ENV}-splunk-iceberg-static"
  role_arn          = data.aws_iam_role.glue_role.arn
  glue_version      = "5.0"
  worker_type       = "G.1X"
  number_of_workers = 10

  security_configuration = aws_glue_security_configuration.glue_security_configuration_splunk.name
  connections            = ["${aws_glue_connection.splunk_vpc_connection.name}"]

  execution_property {
    max_concurrent_runs = 1
  }

  command {
    script_location = "s3://${var.APP}-${var.ENV}-glue-scripts-primary/splunk_etl.py"
  }

  default_arguments = {
    "--additional-python-modules"        = "requests"
    "--enable-glue-datacatalog"          = "true"
    "--datalake-formats"                 = "iceberg"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-job-insights"              = "true"
    "--enable-metrics"                   = "true"
    "--TempDir"                          = var.GLUE_TEMP_BUCKET
    "--spark-event-logs-path"            = var.GLUE_SPARK_LOGS_BUCKET
    "--SPLUNK_HOST"                      = aws_instance.splunk.private_ip
    "--TARGET_DATABASE"                  = aws_glue_catalog_database.splunk_database.name
    "--TARGET_TABLE"                     = aws_glue_catalog_table.splunk_iceberg.name
    "--SPLUNK_ICEBERG_BUCKET"            = var.SPLUNK_ICEBERG_BUCKET
    "--SPLUNK_SECRET_NAME"               = aws_secretsmanager_secret.splunk_credentials.arn
    "--conf" = join(" --conf ", [
      "spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions",
      "spark.sql.catalog.aws_glue=org.apache.iceberg.spark.SparkCatalog",
      "spark.sql.catalog.aws_glue.warehouse=${var.SPLUNK_ICEBERG_BUCKET}",
      "spark.sql.catalog.aws_glue.catalog-impl=org.apache.iceberg.aws.glue.GlueCatalog",
      "spark.sql.catalog.aws_glue.io-impl=org.apache.iceberg.aws.s3.S3FileIO",
      "spark.sql.defaultCatalog=aws_glue"
    ])
  }

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "splunk"
  }
}

resource "aws_glue_job" "splunk_s3_job" {
  name              = "${var.APP}-${var.ENV}-splunk-s3table"
  description       = "${var.APP}-${var.ENV}-splunk-s3table"
  role_arn          = data.aws_iam_role.glue_role.arn
  glue_version      = "5.0"
  worker_type       = "G.1X"
  number_of_workers = 10

  security_configuration = aws_glue_security_configuration.glue_security_configuration_splunk.name
  connections            = ["${aws_glue_connection.splunk_vpc_connection.name}"]

  command {
    script_location = "s3://${var.APP}-${var.ENV}-glue-scripts-primary/s3_splunk.py"
  }

  default_arguments = {
    "--extra-jars"                       = "s3://${var.APP}-${var.ENV}-glue-jars-primary/s3-tables-catalog-for-iceberg-runtime-0.1.7.jar"
    "--TABLE_BUCKET_ARN"                 = "arn:aws:s3tables:${var.AWS_PRIMARY_REGION}:${var.AWS_ACCOUNT_ID}:bucket/${var.APP}-${var.ENV}-splunk"
    "--SPLUNK_HOST"                      = aws_instance.splunk.private_ip
    "--SPLUNK_SECRET_NAME"               = aws_secretsmanager_secret.splunk_credentials.arn
    "--NAMESPACE"                        = var.APP
    "--datalake-formats"                 = "iceberg"
    "--user-jars-first"                  = "true"
    "--additional-python-modules"        = "requests"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-job-insights"              = "true"
    "--enable-metrics"                   = "true"
  }

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "splunk"
  }
}

resource "aws_glue_job" "splunk_s3_create_job" {

  name              = "${var.APP}-${var.ENV}-splunk-s3table-create"
  description       = "${var.APP}-${var.ENV}-splunk-s3table-create"
  role_arn          = data.aws_iam_role.glue_role.arn
  glue_version      = "5.0"
  worker_type       = "G.1X"
  number_of_workers = 10

  security_configuration = aws_glue_security_configuration.glue_security_configuration_splunk.name

  command {
    script_location = "s3://${var.APP}-${var.ENV}-glue-scripts-primary/s3_create_splunk.py"
  }

  default_arguments = {
    "--extra-jars"       = "s3://${var.APP}-${var.ENV}-glue-jars-primary/s3-tables-catalog-for-iceberg-runtime-0.1.7.jar"
    "--TABLE_BUCKET_ARN" = "arn:aws:s3tables:${var.AWS_PRIMARY_REGION}:${var.AWS_ACCOUNT_ID}:bucket/${var.APP}-${var.ENV}-splunk"
    "--NAMESPACE"        = var.APP
    "--datalake-formats" = "iceberg"
    "--user-jars-first"  = "true"
  }

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "splunk"
  }
}

resource "aws_glue_job" "splunk_s3_delete_job" {

  name              = "${var.APP}-${var.ENV}-splunk-s3table-delete"
  description       = "${var.APP}-${var.ENV}-splunk-s3table-delete"
  role_arn          = data.aws_iam_role.glue_role.arn
  glue_version      = "5.0"
  worker_type       = "G.1X"
  number_of_workers = 10

  security_configuration = aws_glue_security_configuration.glue_security_configuration_splunk.name

  command {
    script_location = "s3://${var.APP}-${var.ENV}-glue-scripts-primary/s3_delete_splunk.py"
  }

  default_arguments = {
    "--extra-jars"       = "s3://${var.APP}-${var.ENV}-glue-jars-primary/s3-tables-catalog-for-iceberg-runtime-0.1.7.jar"
    "--TABLE_BUCKET_ARN" = "arn:aws:s3tables:${var.AWS_PRIMARY_REGION}:${var.AWS_ACCOUNT_ID}:bucket/${var.APP}-${var.ENV}-splunk"
    "--NAMESPACE"        = var.APP
    "--datalake-formats" = "iceberg"
    "--user-jars-first"  = "true"
  }

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "splunk"
  }
}

# Glue job trigger for S3 Iceberg Bucket
resource "aws_glue_trigger" "splunk_job_trigger" {

  name     = "splunk-job-trigger"
  type     = "SCHEDULED"
  schedule = "cron(0 7 * * ? *)" # Runs once every day at 7am UTC
  # schedule = "cron(0/5 * * * ? *)" # Runs every 5 minutes

  actions {
    job_name = "${var.APP}-${var.ENV}-splunk"
  }

  enabled = true
}

# Glue job trigger for S3 Table Bucket
resource "aws_glue_trigger" "splunk_s3_job_trigger" {

  name     = "splunk-s3-job-trigger"
  type     = "SCHEDULED"
  schedule = "cron(0 7 * * ? *)" # Runs once every day at 7am UTC
  # schedule = "cron(0/5 * * * ? *)" # Runs every 5 minutes

  actions {
    job_name = "${var.APP}-${var.ENV}-s3-splunk"
  }

  enabled = true
}

