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

resource "aws_glue_security_configuration" "glue_security_configuration" {

  name = "${var.APP}-${var.ENV}-glue-security-configuration"

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

data "aws_s3_bucket" "glue_scripts_bucket" {

  bucket = var.GLUE_SCRIPTS_BUCKET_NAME
}

resource "aws_s3_object" "billing_glue_scripts" {

  for_each   = fileset("${path.module}/", "*.py")
  bucket     = data.aws_s3_bucket.glue_scripts_bucket.id
  key        = each.value
  source     = "${path.module}/${each.value}"
  kms_key_id = data.aws_kms_key.s3_primary_key.arn
}

resource "aws_glue_catalog_database" "glue_database" {

  name = "${var.APP}_${var.ENV}_billing"

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "glue"
  }
}

resource "aws_glue_crawler" "billing_crawler" {

  name          = "${var.APP}-${var.ENV}-billing-crawler"
  database_name = aws_glue_catalog_database.glue_database.name
  role          = data.aws_iam_role.glue_role.arn

  s3_target {
    path = var.BILLING_DATA_FILE
  }

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  security_configuration = aws_glue_security_configuration.glue_security_configuration.name

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
    Usage       = "billing"
  }
}

resource "aws_lakeformation_permissions" "billing_database_permissions" {

  principal   = data.aws_iam_role.glue_role.arn
  permissions = ["DESCRIBE", "CREATE_TABLE", "ALTER", "DROP"]

  database {
    name = "${var.APP}_${var.ENV}_billing"
  }

  depends_on = [aws_glue_catalog_database.glue_database]
}

resource "aws_lakeformation_permissions" "billing_tables_permissions" {

  principal   = data.aws_iam_role.glue_role.arn
  permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]

  table {
    database_name = "${var.APP}_${var.ENV}_billing"
    wildcard      = true
  }

  depends_on = [aws_glue_catalog_database.glue_database, aws_glue_catalog_table.billing_hive, aws_glue_catalog_table.billing_iceberg_static]
}

resource "aws_lakeformation_permissions" "billing_crawler_permissions" {

  principal   = data.aws_iam_role.glue_role.arn
  permissions = ["CREATE_TABLE", "DESCRIBE", "ALTER", "DROP"]

  database {
    name = "${var.APP}_${var.ENV}_billing"
  }

  depends_on = [aws_glue_catalog_database.glue_database]
}

resource "aws_glue_data_catalog_encryption_settings" "encryption_setting" {

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

resource "aws_glue_catalog_table" "billing_hive" {

  name          = "${var.APP}_${var.ENV}_billing_hive"
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

  depends_on = [module.billing_hive_bucket, 
                aws_lakeformation_permissions.hive_deployer_role, 
                aws_lakeformation_permissions.hive_glue_role]

  storage_descriptor {

    location      = "s3://${module.billing_hive_bucket.primary_bucket_name}/"
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
      name = "identity_line_item_id"
      type = "string"
    }

    columns {
      name = "identity_time_interval"
      type = "string"
    }

    columns {
      name = "bill_invoice_id"
      type = "string"
    }

    columns {
      name = "bill_invoicing_entity"
      type = "string"
    }

    columns {
      name = "bill_billing_entity"
      type = "string"
    }

    columns {
      name = "bill_bill_type"
      type = "string"
    }

    columns {
      name = "bill_payer_account_id"
      type = "string"
    }

    columns {
      name = "bill_billing_period_start_date"
      type = "string"
    }

    columns {
      name = "bill_billing_period_end_date"
      type = "string"
    }

    columns {
      name = "line_item_usage_account_id"
      type = "string"
    }

    columns {
      name = "line_item_line_item_type"
      type = "string"
    }

    columns {
      name = "line_item_usage_start_date"
      type = "string"
    }

    columns {
      name = "line_item_usage_end_date"
      type = "string"
    }

    columns {
      name = "line_item_product_code"
      type = "string"
    }

    columns {
      name = "line_item_usage_type"
      type = "string"
    }

    columns {
      name = "line_item_operation"
      type = "string"
    }

    columns {
      name = "line_item_availability_zone"
      type = "string"
    }

    columns {
      name = "line_item_resource_id"
      type = "string"
    }

    columns {
      name = "line_item_usage_amount"
      type = "string"
    }

    columns {
      name = "line_item_normalization_factor"
      type = "string"
    }

    columns {
      name = "line_item_normalized_usage_amount"
      type = "string"
    }

    columns {
      name = "line_item_currency_code"
      type = "string"
    }

    columns {
      name = "line_item_unblended_rate"
      type = "string"
    }

    columns {
      name = "line_item_unblended_cost"
      type = "string"
    }

    columns {
      name = "line_item_blended_rate"
      type = "string"
    }

    columns {
      name = "line_item_blended_cost"
      type = "string"
    }

    columns {
      name = "line_item_line_item_description"
      type = "string"
    }

    columns {
      name = "line_item_tax_type"
      type = "string"
    }

    columns {
      name = "line_item_legal_entity"
      type = "string"
    }

    columns {
      name = "product_product_name"
      type = "string"
    }

    columns {
      name = "product_availability"
      type = "string"
    }

    columns {
      name = "product_category"
      type = "string"
    }

    columns {
      name = "product_ci_type"
      type = "string"
    }

    columns {
      name = "product_cloud_formation_resource_provider"
      type = "string"
    }

    columns {
      name = "product_description"
      type = "string"
    }

    columns {
      name = "product_durability"
      type = "string"
    }

    columns {
      name = "product_endpoint_type"
      type = "string"
    }

    columns {
      name = "product_event_type"
      type = "string"
    }

    columns {
      name = "product_fee_code"
      type = "string"
    }

    columns {
      name = "product_fee_description"
      type = "string"
    }

    columns {
      name = "product_free_query_types"
      type = "string"
    }

    columns {
      name = "product_from_location"
      type = "string"
    }

    columns {
      name = "product_from_location_type"
      type = "string"
    }

    columns {
      name = "product_from_region_code"
      type = "string"
    }

    columns {
      name = "product_group"
      type = "string"
    }

    columns {
      name = "product_group_description"
      type = "string"
    }

    columns {
      name = "product_location"
      type = "string"
    }

    columns {
      name = "product_location_type"
      type = "string"
    }

    columns {
      name = "product_logs_destination"
      type = "string"
    }

    columns {
      name = "product_message_delivery_frequency"
      type = "string"
    }

    columns {
      name = "product_message_delivery_order"
      type = "string"
    }

    columns {
      name = "product_operation"
      type = "string"
    }

    columns {
      name = "product_plato_pricing_type"
      type = "string"
    }

    columns {
      name = "product_product_family"
      type = "string"
    }

    columns {
      name = "product_queue_type"
      type = "string"
    }

    columns {
      name = "product_region"
      type = "string"
    }

    columns {
      name = "product_region_code"
      type = "string"
    }

    columns {
      name = "product_request_type"
      type = "string"
    }

    columns {
      name = "product_service_code"
      type = "string"
    }

    columns {
      name = "product_service_name"
      type = "string"
    }

    columns {
      name = "product_sku"
      type = "string"
    }

    columns {
      name = "product_storage_class"
      type = "string"
    }

    columns {
      name = "product_storage_media"
      type = "string"
    }

    columns {
      name = "product_to_location"
      type = "string"
    }

    columns {
      name = "product_to_location_type"
      type = "string"
    }

    columns {
      name = "product_to_region_code"
      type = "string"
    }

    columns {
      name = "product_transfer_type"
      type = "string"
    }

    columns {
      name = "product_usage_type"
      type = "string"
    }

    columns {
      name = "product_version"
      type = "string"
    }

    columns {
      name = "product_volume_type"
      type = "string"
    }

    columns {
      name = "pricing_rate_code"
      type = "string"
    }

    columns {
      name = "pricing_rate_id"
      type = "string"
    }

    columns {
      name = "pricing_currency"
      type = "string"
    }

    columns {
      name = "pricing_public_on_demand_cost"
      type = "string"
    }

    columns {
      name = "pricing_public_on_demand_rate"
      type = "string"
    }

    columns {
      name = "pricing_term"
      type = "string"
    }

    columns {
      name = "pricing_unit"
      type = "string"
    }

    columns {
      name = "reservation_amortized_upfront_cost_for_usage"
      type = "string"
    }

    columns {
      name = "reservation_amortized_upfront_fee_for_billing_period"
      type = "string"
    }

    columns {
      name = "reservation_effective_cost"
      type = "string"
    }

    columns {
      name = "reservation_end_time"
      type = "string"
    }

    columns {
      name = "reservation_modification_status"
      type = "string"
    }

    columns {
      name = "reservation_normalized_units_per_reservation"
      type = "string"
    }

    columns {
      name = "reservation_number_of_reservations"
      type = "string"
    }

    columns {
      name = "reservation_recurring_fee_for_usage"
      type = "string"
    }

    columns {
      name = "reservation_start_time"
      type = "string"
    }

    columns {
      name = "reservation_subscription_id"
      type = "string"
    }

    columns {
      name = "reservation_total_reserved_normalized_units"
      type = "string"
    }

    columns {
      name = "reservation_total_reserved_units"
      type = "string"
    }

    columns {
      name = "reservation_units_per_reservation"
      type = "string"
    }

    columns {
      name = "reservation_unused_amortized_upfront_fee_for_billing_period"
      type = "string"
    }

    columns {
      name = "reservation_unused_normalized_unit_quantity"
      type = "string"
    }

    columns {
      name = "reservation_unused_quantity"
      type = "string"
    }

    columns {
      name = "reservation_unused_recurring_fee"
      type = "string"
    }

    columns {
      name = "reservation_upfront_value"
      type = "string"
    }

    columns {
      name = "savings_plan_total_commitment_to_date"
      type = "string"
    }

    columns {
      name = "savings_plan_savings_plan_arn"
      type = "string"
    }

    columns {
      name = "savings_plan_savings_plan_rate"
      type = "string"
    }

    columns {
      name = "savings_plan_used_commitment"
      type = "string"
    }

    columns {
      name = "savings_plan_savings_plan_effective_cost"
      type = "string"
    }

    columns {
      name = "savings_plan_amortized_upfront_commitment_for_billing_period"
      type = "string"
    }

    columns {
      name = "savings_plan_recurring_commitment_for_billing_period"
      type = "string"
    }

    columns {
      name = "resource_tags_user_application"
      type = "string"
    }

    columns {
      name = "resource_tags_user_environment"
      type = "string"
    }

    columns {
      name = "resource_tags_user_usage"
      type = "string"
    }
  }
}

resource "aws_glue_catalog_table" "billing_iceberg_static" {

  name          = "${var.APP}_${var.ENV}_billing_iceberg_static"
  database_name = aws_glue_catalog_database.glue_database.name

  table_type = "EXTERNAL_TABLE"

  open_table_format_input {
    iceberg_input {
      metadata_operation = "CREATE"
    }
  }

  depends_on = [module.billing_iceberg_bucket, 
                aws_lakeformation_permissions.iceberg_deployer_role, 
                aws_lakeformation_permissions.iceberg_glue_role]

  storage_descriptor {

    location = "${var.BILLING_ICEBERG_BUCKET}static/"
  }
}

resource "aws_glue_data_quality_ruleset" "billing_hive_ruleset" {

  name        = "billing_hive_ruleset"
  description = "Data quality rules for billing hive table"

  # Target table for the ruleset
  target_table {
    database_name = aws_glue_catalog_database.glue_database.name
    table_name    = aws_glue_catalog_table.billing_hive.name
  }

  # Rules written in DQDL (Data Quality Definition Language)
  ruleset = <<EOF
  Rules = [
    IsComplete "identity_line_item_id",
    IsComplete "identity_time_interval",
    IsComplete "bill_invoice_id",
    IsComplete "bill_invoicing_entity",
    IsComplete "bill_billing_entity",
    IsComplete "bill_bill_type",
    IsComplete "bill_payer_account_id",
    IsComplete "bill_billing_period_start_date",
    IsComplete "bill_billing_period_end_date"
  ]
  EOF
}

resource "aws_glue_data_quality_ruleset" "billing_iceberg_ruleset" {

  name        = "billing_iceberg_ruleset"
  description = "Data quality rules for billing iceberg table"

  # Target table for the ruleset
  target_table {
    database_name = aws_glue_catalog_database.glue_database.name
    table_name    = aws_glue_catalog_table.billing_iceberg_static.name
  }

  # Rules written in DQDL (Data Quality Definition Language)
  ruleset = <<EOF
  Rules = [
    IsComplete "identity_line_item_id",
    IsComplete "identity_time_interval",
    IsComplete "bill_invoice_id",
    IsComplete "bill_invoicing_entity",
    IsComplete "bill_billing_entity",
    IsComplete "bill_bill_type",
    IsComplete "bill_payer_account_id",
    IsComplete "bill_billing_period_start_date",
    IsComplete "bill_billing_period_end_date"
  ]
  EOF
}

resource "aws_glue_job" "billing_hive_job" {

  name              = "${var.APP}-${var.ENV}-billing-hive"
  description       = "${var.APP}-${var.ENV}-billing-hive"
  role_arn          = data.aws_iam_role.glue_role.arn
  glue_version      = "5.0"
  worker_type       = "G.1X"
  number_of_workers = 10

  security_configuration = aws_glue_security_configuration.glue_security_configuration.name

  command {
    script_location = "s3://${var.APP}-${var.ENV}-glue-scripts-primary/billing_hive.py"
  }

  default_arguments = {
    "--SOURCE_FILE"                      = var.BILLING_DATA_FILE
    "--DATABASE_NAME"                    = aws_glue_catalog_database.glue_database.name
    "--TABLE_NAME"                       = aws_glue_catalog_table.billing_hive.name
    "--TempDir"                          = var.GLUE_TEMP_BUCKET
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-job-insights"              = "true"
    "--enable-metrics"                   = "true"
    "--enable-observability-metrics"     = "true"
    "--enable-spark-ui"                  = "true"
    "--spark-event-logs-path"            = var.GLUE_SPARK_LOGS_BUCKET
    "--enable-glue-datacatalog"          = "true"
    "--datalake-formats"                 = "iceberg"
    "--conf"                             = "--conf spark.extraListeners=io.openlineage.spark.agent.OpenLineageSparkListener --conf spark.openlineage.transport.type=amazon_datazone_api --conf spark.openlineage.transport.domainId=${local.SMUS_DOMAIN_ID} --conf spark.openlineage.facets.custom_environment_variables=[AWS_DEFAULT_REGION;GLUE_VERSION;GLUE_COMMAND_CRITERIA;GLUE_PYTHON_VERSION;] --conf spark.glue.accountId=${local.account_id}"
  }

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "billing"
  }
}

resource "aws_glue_job" "billing_static_job" {

  name              = "${var.APP}-${var.ENV}-billing-iceberg-static"
  description       = "${var.APP}-${var.ENV}-billing-iceberg-static"
  role_arn          = data.aws_iam_role.glue_role.arn
  glue_version      = "5.0"
  worker_type       = "G.1X"
  number_of_workers = 10

  security_configuration = aws_glue_security_configuration.glue_security_configuration.name

  command {
    script_location = "s3://${var.APP}-${var.ENV}-glue-scripts-primary/billing_static.py"
  }

  default_arguments = {
    "--SOURCE_FILE"                      = var.BILLING_DATA_FILE
    "--DATABASE_NAME"                    = aws_glue_catalog_database.glue_database.name
    "--TABLE_NAME"                       = aws_glue_catalog_table.billing_iceberg_static.name
    "--TempDir"                          = var.GLUE_TEMP_BUCKET
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-job-insights"              = "true"
    "--enable-metrics"                   = "true"
    "--enable-observability-metrics"     = "true"
    "--enable-spark-ui"                  = "true"
    "--spark-event-logs-path"            = var.GLUE_SPARK_LOGS_BUCKET
    "--enable-glue-datacatalog"          = "true"
    "--datalake-formats"                 = "iceberg"
    "--conf"                             = "spark.sql.defaultCatalog=glue_catalog --conf spark.sql.catalog.glue_catalog.warehouse=${var.BILLING_ICEBERG_BUCKET}static/ --conf spark.sql.catalog.glue_catalog=org.apache.iceberg.spark.SparkCatalog --conf spark.sql.catalog.glue_catalog.catalog-impl=org.apache.iceberg.aws.glue.GlueCatalog --conf spark.sql.catalog.glue_catalog.io-impl=org.apache.iceberg.aws.s3.S3FileIO --conf spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions --conf spark.extraListeners=io.openlineage.spark.agent.OpenLineageSparkListener --conf spark.openlineage.transport.type=amazon_datazone_api --conf spark.openlineage.transport.domainId=${local.SMUS_DOMAIN_ID} --conf spark.openlineage.facets.custom_environment_variables=[AWS_DEFAULT_REGION;GLUE_VERSION;GLUE_COMMAND_CRITERIA;GLUE_PYTHON_VERSION;] --conf spark.glue.accountId=${local.account_id}"
  }

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "billing"
  }
}

resource "aws_glue_job" "billing_dynamic_job" {

  name              = "${var.APP}-${var.ENV}-billing-iceberg-dynamic"
  description       = "${var.APP}-${var.ENV}-billing-iceberg-dynamic"
  role_arn          = data.aws_iam_role.glue_role.arn
  glue_version      = "5.0"
  worker_type       = "G.1X"
  number_of_workers = 10

  security_configuration = aws_glue_security_configuration.glue_security_configuration.name

  command {
    script_location = "s3://${var.APP}-${var.ENV}-glue-scripts-primary/billing_dynamic.py"
  }

  default_arguments = {
    "--SOURCE_FILE"                      = var.BILLING_DATA_FILE
    "--ICEBERG_BUCKET"                   = var.BILLING_ICEBERG_BUCKET
    "--TARGET_DATABASE_NAME"             = aws_glue_catalog_database.glue_database.name
    "--CRAWLER_NAME"                     = aws_glue_crawler.billing_crawler.name
    "--TempDir"                          = var.GLUE_TEMP_BUCKET
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-job-insights"              = "true"
    "--enable-metrics"                   = "true"
    "--enable-observability-metrics"     = "true"
    "--enable-spark-ui"                  = "true"
    "--spark-event-logs-path"            = var.GLUE_SPARK_LOGS_BUCKET
    "--enable-glue-datacatalog"          = "true"
    "--datalake-formats"                 = "iceberg"
    "--conf"                             = "spark.sql.defaultCatalog=glue_catalog --conf spark.sql.catalog.glue_catalog.warehouse=${var.BILLING_ICEBERG_BUCKET} --conf spark.sql.catalog.glue_catalog=org.apache.iceberg.spark.SparkCatalog --conf spark.sql.catalog.glue_catalog.catalog-impl=org.apache.iceberg.aws.glue.GlueCatalog --conf spark.sql.catalog.glue_catalog.io-impl=org.apache.iceberg.aws.s3.S3FileIO --conf spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions --conf spark.extraListeners=io.openlineage.spark.agent.OpenLineageSparkListener --conf spark.openlineage.transport.type=amazon_datazone_api --conf spark.openlineage.transport.domainId=${local.SMUS_DOMAIN_ID} --conf spark.openlineage.facets.custom_environment_variables=[AWS_DEFAULT_REGION;GLUE_VERSION;GLUE_COMMAND_CRITERIA;GLUE_PYTHON_VERSION;] --conf spark.glue.accountId=${local.account_id}"
  }

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "billing"
  }
}

resource "aws_glue_job" "billing_s3_create_job" {

  name              = "${var.APP}-${var.ENV}-billing-s3table-create"
  description       = "${var.APP}-${var.ENV}-billing-s3table-create"
  role_arn          = data.aws_iam_role.glue_role.arn
  glue_version      = "5.0"
  worker_type       = "G.1X"
  number_of_workers = 10

  security_configuration = aws_glue_security_configuration.glue_security_configuration.name

  command {
    script_location = "s3://${var.APP}-${var.ENV}-glue-scripts-primary/billing_s3_create.py"
  }

  default_arguments = {
    "--extra-jars"       = "s3://${var.APP}-${var.ENV}-glue-jars-primary/s3-tables-catalog-for-iceberg-runtime-0.1.7.jar"
    "--NAMESPACE"        = var.APP
    "--TABLE_BUCKET_ARN" = "arn:aws:s3tables:${var.AWS_PRIMARY_REGION}:${var.AWS_ACCOUNT_ID}:bucket/${var.APP}-${var.ENV}-billing"
    "--datalake-formats" = "iceberg"
    "--user-jars-first"  = "true"
  }

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "billing"
  }
}

resource "aws_glue_job" "billing_s3_delete_job" {

  name              = "${var.APP}-${var.ENV}-billing-s3table-delete"
  description       = "${var.APP}-${var.ENV}-billing-s3table-delete"
  role_arn          = data.aws_iam_role.glue_role.arn
  glue_version      = "5.0"
  worker_type       = "G.1X"
  number_of_workers = 10

  security_configuration = aws_glue_security_configuration.glue_security_configuration.name

  command {
    script_location = "s3://${var.APP}-${var.ENV}-glue-scripts-primary/billing_s3_delete.py"
  }

  default_arguments = {
    "--extra-jars"       = "s3://${var.APP}-${var.ENV}-glue-jars-primary/s3-tables-catalog-for-iceberg-runtime-0.1.7.jar"
    "--NAMESPACE"        = var.APP
    "--TABLE_BUCKET_ARN" = "arn:aws:s3tables:${var.AWS_PRIMARY_REGION}:${var.AWS_ACCOUNT_ID}:bucket/${var.APP}-${var.ENV}-billing"
    "--datalake-formats" = "iceberg"
    "--user-jars-first"  = "true"
  }

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "billing"
  }
}

resource "aws_glue_job" "billing_s3_job" {

  name              = "${var.APP}-${var.ENV}-billing-s3table"
  description       = "${var.APP}-${var.ENV}-billing-s3table"
  role_arn          = data.aws_iam_role.glue_role.arn
  glue_version      = "5.0"
  worker_type       = "G.1X"
  number_of_workers = 10

  security_configuration = aws_glue_security_configuration.glue_security_configuration.name

  command {
    script_location = "s3://${var.APP}-${var.ENV}-glue-scripts-primary/billing_s3.py"
  }

  default_arguments = {
    "--SOURCE_FILE"          = var.BILLING_DATA_FILE
    "--NAMESPACE"            = var.APP
    "--TABLE_BUCKET_ARN"     = "arn:aws:s3tables:${var.AWS_PRIMARY_REGION}:${var.AWS_ACCOUNT_ID}:bucket/${var.APP}-${var.ENV}-billing"
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
    Usage       = "billing"
  }
}

resource "aws_glue_trigger" "billing_static_job_trigger" {

  name     = "billing-static-job-trigger"
  type     = "SCHEDULED"
  schedule = "cron(0 7 * * ? *)"

  actions {
    job_name = aws_glue_job.billing_static_job.name
  }

  enabled = false
}

resource "aws_glue_trigger" "billing_s3_job_trigger" {

  name     = "billing-s3-job-trigger"
  type     = "SCHEDULED"
  schedule = "cron(0 7 * * ? *)"

  actions {
    job_name = aws_glue_job.billing_s3_job.name
  }

  enabled = false
}

resource "aws_glue_trigger" "billing_crawler_trigger" {

  name          = "${var.APP}-${var.ENV}-billing-crawler-trigger"
  type          = "ON_DEMAND"
  workflow_name = aws_glue_workflow.billing_workflow.name

  actions {
    crawler_name = aws_glue_crawler.billing_crawler.name
  }

  enabled = false
}

resource "aws_glue_trigger" "billing_iceberg_job_trigger" {

  name          = "${var.APP}-${var.ENV}-billing-iceberg-job-trigger"
  type          = "CONDITIONAL"
  workflow_name = aws_glue_workflow.billing_workflow.name

  actions {
    job_name = aws_glue_job.billing_dynamic_job.name
  }

  predicate {
    conditions {
      crawler_name = aws_glue_crawler.billing_crawler.name
      crawl_state  = "SUCCEEDED"
    }
  }
}

resource "aws_glue_workflow" "billing_workflow" {

  name        = "${var.APP}-${var.ENV}-billing-workflow"
  description = "Workflow for billing processing"

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "billing"
  }
}
