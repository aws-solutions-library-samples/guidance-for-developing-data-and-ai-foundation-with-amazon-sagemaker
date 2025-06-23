// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_kms_key" "glue_kms_key" {

  provider = aws.primary
  key_id   = "alias/${var.GLUE_KMS_KEY_ALIAS}"
}

data "aws_kms_key" "cloudwatch_kms_key" {

  provider = aws.primary
  key_id   = "alias/${var.CLOUDWATCH_KMS_KEY_ALIAS}"
}

data "aws_iam_role" "glue_role" {

  name = var.GLUE_ROLE_NAME
}

data "aws_iam_role" "eventbridge_role" {

  name = var.EVENTBRIDGE_ROLE_NAME

}

resource "aws_glue_security_configuration" "glue_security_configuration_inventory" {

  name = "${var.APP}-${var.ENV}-glue-security-configuration-inventory"

  encryption_configuration {
    cloudwatch_encryption {
      cloudwatch_encryption_mode = "SSE-KMS"
      kms_key_arn = data.aws_kms_key.cloudwatch_kms_key.arn
    }

    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = "CSE-KMS"
      kms_key_arn = data.aws_kms_key.glue_kms_key.arn
    }

    s3_encryption {
      s3_encryption_mode = "SSE-KMS"
      kms_key_arn = data.aws_kms_key.glue_kms_key.arn
    }
  }
}

data "aws_s3_bucket" "glue_scripts_bucket" {

  bucket = var.GLUE_SCRIPTS_BUCKET_NAME
}

resource "aws_s3_object" "inventory_glue_scripts" {

  for_each   = fileset("${path.module}/", "*.py")
  bucket     = data.aws_s3_bucket.glue_scripts_bucket.id
  key        = each.value
  source     = "${path.module}/${each.value}"
  kms_key_id = data.aws_kms_key.s3_primary_key.arn
}

resource "aws_glue_catalog_database" "glue_database" {

  name = "${var.APP}_${var.ENV}_inventory"

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "glue"
  }
}

resource "aws_lakeformation_permissions" "database_permissions" {

  principal   = data.aws_iam_role.glue_role.arn
  permissions = ["DESCRIBE", "CREATE_TABLE", "ALTER", "DROP"]

  database {
    name = "${var.APP}_${var.ENV}_inventory"
  }

  depends_on = [aws_glue_catalog_database.glue_database]
}

resource "aws_lakeformation_permissions" "tables_permissions" {

  principal   = data.aws_iam_role.glue_role.arn
  permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]

  table {
    database_name = "${var.APP}_${var.ENV}_inventory"
    wildcard      = true
  }

  depends_on = [aws_glue_catalog_database.glue_database,
    aws_glue_catalog_table.inventory_hive,
  aws_glue_catalog_table.inventory_iceberg_static]
}

resource "aws_lakeformation_permissions" "inventory_crawler_permissions" {

  principal   = data.aws_iam_role.glue_role.arn
  permissions = ["CREATE_TABLE", "DESCRIBE", "ALTER", "DROP"]

  database {
    name = "${var.APP}_${var.ENV}_inventory"
  }

  depends_on = [aws_glue_catalog_database.glue_database]
}

resource "aws_glue_crawler" "inventory_crawler" {

  name          = "${var.APP}-${var.ENV}-inventory-crawler"
  role          = data.aws_iam_role.glue_role.arn
  database_name = aws_glue_catalog_database.glue_database.name

  s3_target {
    path = var.INVENTORY_DATA_DESTINATION_BUCKET
  }

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "DEPRECATE_IN_DATABASE"
  }

  security_configuration = aws_glue_security_configuration.glue_security_configuration_inventory.name

  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Tables = {
        AddOrUpdateBehavior = "MergeNewColumns"
        TableThreshold      = 1
      }
    }
    Grouping = {
      TableGroupingPolicy = "CombineCompatibleSchemas"
    }
  })

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "inventory"
  }
}

resource "aws_glue_data_catalog_encryption_settings" "encryption_setting" {

  data_catalog_encryption_settings {

    connection_password_encryption {
      aws_kms_key_id                       = data.aws_kms_key.glue_kms_key.arn
      return_connection_password_encrypted = true
    }

    encryption_at_rest {
      catalog_encryption_mode         = "SSE-KMS"
      sse_aws_kms_key_id              = data.aws_kms_key.glue_kms_key.arn
    }
  }
}

resource "aws_glue_catalog_table" "inventory_hive" {

  name          = "${var.APP}_${var.ENV}_inventory_hive"
  database_name = aws_glue_catalog_database.glue_database.name

  table_type = "EXTERNAL_TABLE"

  parameters = {

    "classification"         = "csv"
    "compressionType"        = "gzip"
    "areColumnsQuoted"       = "true"
    "delimiter"              = ","
    "skip.header.line.count" = "1"
    "typeOfData"             = "file"
    "EXTERNAL"               = "TRUE"
  }

  depends_on = [module.inventory_hive_bucket, 
                aws_lakeformation_permissions.hive_deployer_role,
                aws_lakeformation_permissions.hive_glue_role]

  storage_descriptor {

    location      = "s3://${module.inventory_hive_bucket.primary_bucket_name}/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "csv-serde"
      serialization_library = "org.apache.hadoop.hive.serde2.OpenCSVSerde"

      parameters = {
        "separatorChar" = ","
        "quoteChar"     = "\""
        "escapeChar"    = "\\"
      }
    }

    columns {
      name = "bucket"
      type = "string"
    }

    columns {
      name = "key"
      type = "string"
    }

    columns {
      name = "size"
      type = "string"
    }

    columns {
      name = "last_modified_date"
      type = "string"
    }

    columns {
      name = "etag"
      type = "string"
    }

    columns {
      name = "storage_class"
      type = "string"
    }

    columns {
      name = "is_multipart_uploaded"
      type = "string"
    }

    columns {
      name = "replication_status"
      type = "string"
    }

    columns {
      name = "encryption_status"
      type = "string"
    }

    columns {
      name = "is_latest"
      type = "string"
    }

    columns {
      name = "object_lock_mode"
      type = "string"
    }

    columns {
      name = "object_lock_legal_hold_status"
      type = "string"
    }

    columns {
      name = "bucket_key_status"
      type = "string"
    }

    columns {
      name = "object_lock_retain_until_date"
      type = "string"
    }

    columns {
      name = "checksum_algorithm"
      type = "string"
    }

    columns {
      name = "object_access_control_list"
      type = "string"
    }

    columns {
      name = "object_owner"
      type = "string"
    }
  }
}

resource "aws_glue_catalog_table" "inventory_iceberg_static" {

  name          = "${var.APP}_${var.ENV}_inventory_iceberg_static"
  database_name = aws_glue_catalog_database.glue_database.name

  table_type = "EXTERNAL_TABLE"

  open_table_format_input {
    iceberg_input {
      metadata_operation = "CREATE"
    }
  }

  depends_on = [module.inventory_iceberg_bucket, 
                aws_lakeformation_permissions.iceberg_deployer_role,
                aws_lakeformation_permissions.iceberg_glue_role]

  storage_descriptor {

    location = "${var.INVENTORY_ICEBERG_BUCKET}static/"

    columns {
      name = "bucket"
      type = "string"
    }

    columns {
      name = "key"
      type = "string"
    }

    columns {
      name = "size"
      type = "string"
    }

    columns {
      name = "last_modified_date"
      type = "string"
    }

    columns {
      name = "etag"
      type = "string"
    }

    columns {
      name = "storage_class"
      type = "string"
    }

    columns {
      name = "is_multipart_uploaded"
      type = "string"
    }

    columns {
      name = "replication_status"
      type = "string"
    }

    columns {
      name = "encryption_status"
      type = "string"
    }

    columns {
      name = "is_latest"
      type = "string"
    }

    columns {
      name = "object_lock_mode"
      type = "string"
    }

    columns {
      name = "object_lock_legal_hold_status"
      type = "string"
    }

    columns {
      name = "bucket_key_status"
      type = "string"
    }

    columns {
      name = "object_lock_retain_until_date"
      type = "string"
    }

    columns {
      name = "checksum_algorithm"
      type = "string"
    }

    columns {
      name = "object_access_control_list"
      type = "string"
    }

    columns {
      name = "object_owner"
      type = "string"
    }
  }
}

resource "aws_glue_data_quality_ruleset" "inventory_hive_ruleset" {

  name        = "inventory-hive-ruleset"
  description = "Data quality rules for inventory hive table"

  # Target table for the ruleset
  target_table {
    database_name = aws_glue_catalog_database.glue_database.name
    table_name    = aws_glue_catalog_table.inventory_hive.name
  }

  # Rules written in DQDL (Data Quality Definition Language)
  ruleset = <<EOF
  Rules = [
    IsComplete "bucket",
    IsComplete "key",
    IsComplete "size",
    IsComplete "etag",
    IsComplete "storage_class",
    IsComplete "replication_status",
    IsComplete "encryption_status",
    IsComplete "is_latest",
    IsComplete "object_lock_mode"
  ]
  EOF
}

resource "aws_glue_data_quality_ruleset" "inventory_iceberg_ruleset" {

  name        = "inventory-iceberg-ruleset"
  description = "Data quality rules for inventory iceberg table"

  # Target table for the ruleset
  target_table {
    database_name = aws_glue_catalog_database.glue_database.name
    table_name    = aws_glue_catalog_table.inventory_iceberg_static.name
  }

  # Rules written in DQDL (Data Quality Definition Language)
  ruleset = <<EOF
  Rules = [
    IsComplete "bucket",
    IsComplete "key",
    IsComplete "size",
    IsComplete "etag",
    IsComplete "storage_class",
    IsComplete "replication_status",
    IsComplete "encryption_status",
    IsComplete "is_latest",
    IsComplete "object_lock_mode"
  ]
  EOF
}
 
resource "aws_glue_job" "inventory_hive_job" {

  name              = "${var.APP}-${var.ENV}-inventory-hive"
  description       = "${var.APP}-${var.ENV}-inventory-hive"
  role_arn          = data.aws_iam_role.glue_role.arn
  glue_version      = "5.0"
  worker_type       = "G.1X"
  number_of_workers = 10

  security_configuration = aws_glue_security_configuration.glue_security_configuration_inventory.name

  command {
    script_location = "s3://${var.APP}-${var.ENV}-glue-scripts-primary/inventory_hive.py"
  }

  default_arguments = {
    "--SOURCE_FILE"                      = var.INVENTORY_DATA_FILE
    "--DATABASE_NAME"                    = aws_glue_catalog_database.glue_database.name
    "--TABLE_NAME"                       = aws_glue_catalog_table.inventory_hive.name
    "--TempDir"                          = var.GLUE_TEMP_BUCKET
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-job-insights"              = "true"
    "--enable-metrics"                   = "true"
    "--enable-observability-metrics"     = "true"
    "--enable-spark-ui"                  = "true"
    "--spark-event-logs-path"            = var.GLUE_SPARK_LOGS_BUCKET
    "--enable-glue-datacatalog"          = "true"
    "--conf"                             = "spark.extraListeners=io.openlineage.spark.agent.OpenLineageSparkListener --conf spark.openlineage.transport.type=amazon_datazone_api --conf spark.openlineage.transport.domainId=${local.SMUS_DOMAIN_ID} --conf spark.openlineage.facets.custom_environment_variables=[AWS_DEFAULT_REGION;GLUE_VERSION;GLUE_COMMAND_CRITERIA;GLUE_PYTHON_VERSION;] --conf spark.glue.accountId=${local.account_id}"
  }

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "inventory"
  }
}

resource "aws_glue_job" "inventory_static_job" {

  name              = "${var.APP}-${var.ENV}-inventory-iceberg-static"
  description       = "${var.APP}-${var.ENV}-inventory-iceberg-static"
  role_arn          = data.aws_iam_role.glue_role.arn
  glue_version      = "5.0"
  worker_type       = "G.1X"
  number_of_workers = 10

  security_configuration = aws_glue_security_configuration.glue_security_configuration_inventory.name

  command {
    script_location = "s3://${var.APP}-${var.ENV}-glue-scripts-primary/inventory_static.py"
  }

  default_arguments = {
    "--SOURCE_FILE"                      = var.INVENTORY_DATA_FILE
    "--DATABASE_NAME"                    = aws_glue_catalog_database.glue_database.name
    "--TABLE_NAME"                       = aws_glue_catalog_table.inventory_iceberg_static.name
    "--TempDir"                          = var.GLUE_TEMP_BUCKET
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-job-insights"              = "true"
    "--enable-metrics"                   = "true"
    "--enable-observability-metrics"     = "true"
    "--enable-spark-ui"                  = "true"
    "--spark-event-logs-path"            = var.GLUE_SPARK_LOGS_BUCKET
    "--enable-glue-datacatalog"          = "true"
    "--datalake-formats"                 = "iceberg"
    "--conf"                             = "spark.sql.defaultCatalog=glue_catalog --conf spark.sql.catalog.glue_catalog.warehouse=${var.INVENTORY_ICEBERG_BUCKET}static/ --conf spark.sql.catalog.glue_catalog=org.apache.iceberg.spark.SparkCatalog --conf spark.sql.catalog.glue_catalog.catalog-impl=org.apache.iceberg.aws.glue.GlueCatalog --conf spark.sql.catalog.glue_catalog.io-impl=org.apache.iceberg.aws.s3.S3FileIO --conf spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions --conf spark.extraListeners=io.openlineage.spark.agent.OpenLineageSparkListener --conf spark.openlineage.transport.type=amazon_datazone_api --conf spark.openlineage.transport.domainId=${local.SMUS_DOMAIN_ID} --conf spark.openlineage.facets.custom_environment_variables=[AWS_DEFAULT_REGION;GLUE_VERSION;GLUE_COMMAND_CRITERIA;GLUE_PYTHON_VERSION;] --conf spark.glue.accountId=${local.account_id}"
  }

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "inventory"
  }
}

resource "aws_glue_job" "inventory_dynamic_job" {

  name              = "${var.APP}-${var.ENV}-inventory-iceberg-dynamic"
  description       = "${var.APP}-${var.ENV}-inventory-iceberg-dynamic"
  role_arn          = data.aws_iam_role.glue_role.arn
  glue_version      = "5.0"
  worker_type       = "G.1X"
  number_of_workers = 10

  security_configuration = aws_glue_security_configuration.glue_security_configuration_inventory.name

  command {
    script_location = "s3://${var.APP}-${var.ENV}-glue-scripts-primary/inventory_dynamic.py"
  }

  default_arguments = {
    "--SOURCE_FILE"                      = var.INVENTORY_DATA_FILE
    "--ICEBERG_BUCKET"                   = var.INVENTORY_ICEBERG_BUCKET
    "--TARGET_DATABASE_NAME"             = aws_glue_catalog_database.glue_database.name
    "--CRAWLER_NAME"                     = aws_glue_crawler.inventory_crawler.name
    "--TempDir"                          = var.GLUE_TEMP_BUCKET
    "--WORKFLOW_NAME"                    = "${aws_glue_workflow.inventory_workflow.name}"
    "--WORKFLOW_RUN_ID"                  = "$(workflow_run_id)"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-job-insights"              = "true"
    "--enable-metrics"                   = "true"
    "--enable-observability-metrics"     = "true"
    "--enable-spark-ui"                  = "true"
    "--spark-event-logs-path"            = var.GLUE_SPARK_LOGS_BUCKET
    "--enable-glue-datacatalog"          = "true"
    "--datalake-formats"                 = "iceberg"
    "--conf"                             = "spark.sql.defaultCatalog=glue_catalog --conf spark.sql.catalog.glue_catalog.warehouse=${var.INVENTORY_ICEBERG_BUCKET} --conf spark.sql.catalog.glue_catalog=org.apache.iceberg.spark.SparkCatalog --conf spark.sql.catalog.glue_catalog.catalog-impl=org.apache.iceberg.aws.glue.GlueCatalog --conf spark.sql.catalog.glue_catalog.io-impl=org.apache.iceberg.aws.s3.S3FileIO --conf spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions"
  }

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "inventory"
  }
}

resource "aws_glue_job" "inventory_s3_create_job" {

  name              = "${var.APP}-${var.ENV}-inventory-s3table-create"
  description       = "${var.APP}-${var.ENV}-inventory-s3table-create"
  role_arn          = data.aws_iam_role.glue_role.arn
  glue_version      = "5.0"
  worker_type       = "G.1X"
  number_of_workers = 10

  security_configuration = aws_glue_security_configuration.glue_security_configuration_inventory.name

  command {
    script_location = "s3://${var.APP}-${var.ENV}-glue-scripts-primary/inventory_s3_create.py"
  }

  default_arguments = {
    "--extra-jars"       = "s3://${var.APP}-${var.ENV}-glue-jars-primary/s3-tables-catalog-for-iceberg-runtime-0.1.7.jar"
    "--NAMESPACE"        = var.APP
    "--TABLE_BUCKET_ARN" = "arn:aws:s3tables:${var.AWS_PRIMARY_REGION}:${var.AWS_ACCOUNT_ID}:bucket/${var.APP}-${var.ENV}-inventory"
    "--datalake-formats" = "iceberg"
    "--user-jars-first"  = "true"
  }

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "inventory"
  }
}

resource "aws_glue_job" "inventory_s3_delete_job" {

  name              = "${var.APP}-${var.ENV}-inventory-s3table-delete"
  description       = "${var.APP}-${var.ENV}-inventory-s3table-delete"
  role_arn          = data.aws_iam_role.glue_role.arn
  glue_version      = "5.0"
  worker_type       = "G.1X"
  number_of_workers = 10

  security_configuration = aws_glue_security_configuration.glue_security_configuration_inventory.name

  command {
    script_location = "s3://${var.APP}-${var.ENV}-glue-scripts-primary/inventory_s3_delete.py"
  }

  default_arguments = {
    "--extra-jars"       = "s3://${var.APP}-${var.ENV}-glue-jars-primary/s3-tables-catalog-for-iceberg-runtime-0.1.7.jar"
    "--NAMESPACE"        = var.APP
    "--TABLE_BUCKET_ARN" = "arn:aws:s3tables:${var.AWS_PRIMARY_REGION}:${var.AWS_ACCOUNT_ID}:bucket/${var.APP}-${var.ENV}-inventory"
    "--datalake-formats" = "iceberg"
    "--user-jars-first"  = "true"
  }

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "inventory"
  }
}

resource "aws_glue_job" "inventory_s3_job" {

  name              = "${var.APP}-${var.ENV}-inventory-s3table"
  description       = "${var.APP}-${var.ENV}-inventory-s3table"
  role_arn          = data.aws_iam_role.glue_role.arn
  glue_version      = "5.0"
  worker_type       = "G.1X"
  number_of_workers = 10

  security_configuration = aws_glue_security_configuration.glue_security_configuration_inventory.name

  command {
    script_location = "s3://${var.APP}-${var.ENV}-glue-scripts-primary/inventory_s3.py"
  }

  default_arguments = {
    "--SOURCE_FILE"          = var.INVENTORY_DATA_FILE
    "--NAMESPACE"            = var.APP
    "--TABLE_BUCKET_ARN"     = "arn:aws:s3tables:${var.AWS_PRIMARY_REGION}:${var.AWS_ACCOUNT_ID}:bucket/${var.APP}-${var.ENV}-inventory"
    "--extra-jars"           = "s3://${var.APP}-${var.ENV}-glue-jars-primary/s3-tables-catalog-for-iceberg-runtime-0.1.7.jar"
    "--datalake-formats"     = "iceberg"
    "--user-jars-first"      = "true"
    "--TempDir"                          = var.GLUE_TEMP_BUCKET
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-job-insights"              = "true"
    "--enable-metrics"                   = "true"
    "--enable-observability-metrics"     = "true"
    "--enable-spark-ui"                  = "true"
    "--spark-event-logs-path"            = var.GLUE_SPARK_LOGS_BUCKET
  }

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "inventory"
  }
}

resource "aws_glue_trigger" "inventory_static_job_trigger" {

  name     = "inventory-static-job-trigger"
  type     = "SCHEDULED"
  schedule = "cron(0 7 * * ? *)"

  actions {
    job_name = aws_glue_job.inventory_static_job.name
  }

  enabled = false
}

resource "aws_glue_trigger" "inventory_s3_job_trigger" {

  name     = "inventory-s3-job-trigger"
  type     = "SCHEDULED"
  schedule = "cron(0 7 * * ? *)"

  actions {
    job_name = aws_glue_job.inventory_s3_job.name
  }

  enabled = false
}

resource "aws_glue_trigger" "inventory_crawler_trigger" {

  name          = "${var.APP}-${var.ENV}-inventory-crawler-trigger"
  type          = "ON_DEMAND"
  workflow_name = aws_glue_workflow.inventory_workflow.name

  actions {
    crawler_name = aws_glue_crawler.inventory_crawler.name
  }

  enabled = false
}

resource "aws_glue_trigger" "inventory_iceberg_job_trigger" {

  name          = "${var.APP}-${var.ENV}-inventory-iceberg-job-trigger"
  type          = "CONDITIONAL"
  workflow_name = aws_glue_workflow.inventory_workflow.name

  actions {
    job_name = aws_glue_job.inventory_dynamic_job.name
  }

  predicate {
    conditions {
      crawler_name = aws_glue_crawler.inventory_crawler.name
      crawl_state  = "SUCCEEDED"
    }
  }
}

resource "aws_glue_workflow" "inventory_workflow" {

  name        = "${var.APP}-${var.ENV}-inventory-workflow"
  description = "Workflow for inventory processing"

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "inventory"
  }
}
