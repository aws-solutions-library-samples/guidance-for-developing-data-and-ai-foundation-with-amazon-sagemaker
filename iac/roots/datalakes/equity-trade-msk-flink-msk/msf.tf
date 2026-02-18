// Copyright 2025 Amazon.com and its affiliates; all rights reserved.
// This file is Amazon Web Services Content and may not be duplicated or distributed without permission.

# resource "aws_s3_bucket" "flink_bucket" {

#   bucket = var.FLINK_S3_BUCKET
# }

data "aws_kms_key" "s3_kms_key" {

  key_id = "alias/${var.S3_KMS_KEY_ALIAS}"
}

module "flink_bucket" {

  source = "../../../templates/modules/bucket"

  APP     = var.APP
  ENV     = var.ENV
  NAME    = "equity-trade-msk-flink-msk"
  USAGE   = "equity-trade"
  CMK_ARN = data.aws_kms_key.s3_kms_key.arn
}

resource "aws_s3_object" "flink_code" {

  bucket = module.flink_bucket.bucket_id
  key    = var.FLINK_S3_FILE_KEY
  source = "${path.module}/java-app/msf/target/msf-1.0-SNAPSHOT.jar"
  etag   = filemd5("${path.module}/java-app/msf/target/msf-1.0-SNAPSHOT.jar")
}

data "aws_iam_policy_document" "flink_app_assume_role" {

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["kinesisanalytics.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "flink_app" {

  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:*Object",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${var.FLINK_S3_BUCKET}",
      "arn:aws:s3:::${var.FLINK_S3_BUCKET}/*"
    ]
  }
  statement {
    actions = [
      "kafka-cluster:Connect",
      "kafka-cluster:DescribeCluster",
      "kafka-cluster:AlterCluster",
      "kafka:GetBootstrapBrokers",
      "kafka-cluster:Connect",
      "kafka-cluster:AlterGroup",
      "kafka-cluster:DescribeGroup",
      "kafka-cluster:DeleteGroup",
      "kafka-cluster:*Topic*",
      "kafka-cluster:WriteData",
      "kafka-cluster:ReadData"
    ]
    resources = [
      "arn:aws:kafka:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:cluster/${var.APP}-${var.ENV}-msk-cluster/*",
      "arn:aws:kafka:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:topic/${var.APP}-${var.ENV}-msk-cluster/*",
      "arn:aws:kafka:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:group/${var.APP}-${var.ENV}-msk-cluster/*"
    ]
  }
  statement {
    actions = [
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]
    resources = [
      aws_cloudwatch_log_group.flink_app.arn,
      aws_cloudwatch_log_stream.flink_app.arn,
      "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*"
    ]
  }
  statement {
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey"
    ]
    resources = [
      data.aws_kms_key.s3_kms_key.arn
    ]
  }
}

resource "aws_iam_role" "flink_app_role" {

  name               = "${var.APP}-${var.ENV}-flink-app-role"
  assume_role_policy = data.aws_iam_policy_document.flink_app_assume_role.json
}

resource "aws_iam_role_policy_attachment" "attachment_1" {

  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
  role       = aws_iam_role.flink_app_role.id
}

resource "aws_iam_role_policy" "flink_app" {

  name   = "${var.APP}-policy"
  role   = aws_iam_role.flink_app_role.id
  policy = data.aws_iam_policy_document.flink_app.json
}

resource "aws_cloudwatch_log_group" "flink_app" {

  name              = "/aws/kinesis-analytics/${var.APP}-${var.ENV}-flink-app"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_stream" "flink_app" {

  name           = "${var.APP}-${var.ENV}-flink-app-log-stream"
  log_group_name = aws_cloudwatch_log_group.flink_app.name
}

resource "aws_kinesisanalyticsv2_application" "flink_app" {

  name                   = "equity-trade-msk-flink-msk"
  runtime_environment    = var.FLINK_APP_RUNTIME_ENV
  service_execution_role = aws_iam_role.flink_app_role.arn
  start_application      = var.FLINK_APP_START
  force_stop             = true

  depends_on = [aws_s3_object.flink_code]

  cloudwatch_logging_options {
    log_stream_arn = aws_cloudwatch_log_stream.flink_app.arn
  }

  application_configuration {

    run_configuration {
      application_restore_configuration {
        application_restore_type = "RESTORE_FROM_LATEST_SNAPSHOT"
      }
    }

    flink_application_configuration {

      checkpoint_configuration {
        configuration_type = "DEFAULT"
      }

      monitoring_configuration {
        configuration_type = "CUSTOM"
        log_level          = var.FLINK_APP_MONITORING_LOG_LEVEL
        metrics_level      = var.FLINK_APP_MONITORING_METRICS_LEVEL
      }

      parallelism_configuration {
        auto_scaling_enabled = var.FLINK_APP_AUTOSCALING_ENABLED
        configuration_type   = "CUSTOM"
        parallelism          = var.FLINK_APP_PARALLELISM
        parallelism_per_kpu  = var.FLINK_APP_PARALLELISM_PER_KPU
      }
    }
    environment_properties {
      property_group {
        property_group_id = "FlinkApplicationProperties"
        property_map = {
          "async.capacity"                            = 500
          "aws.region"                                = var.AWS_PRIMARY_REGION
          "bootstrap.servers"                         = local.MSK_ENDPOINT
          "sink.sasl.client.callback.handler.class"   = "software.amazon.msk.auth.iam.IAMClientCallbackHandler"
          "sink.sasl.jaas.config"                     = "software.amazon.msk.auth.iam.IAMLoginModule required;"
          "sink.sasl.mechanism"                       = "AWS_MSK_IAM"
          "sink.security.protocol"                    = "SASL_SSL"
          "sink.ssl.truststore.location"              = "/usr/lib/jvm/java-11-amazon-corretto/lib/security/cacerts"
          "sink.ssl.truststore.password"              = "changeit"
          "sink.topic"                                = var.FLINK_APP_ENVIRONMENT_VARIABLES["SINK_TOPIC_NAME"]
          "sink.transaction.timeout.ms"               = 45000
          "source.execution.checkpointing.mode"       = "AT_LEAST_ONCE"
          "source.sasl.client.callback.handler.class" = "software.amazon.msk.auth.iam.IAMClientCallbackHandler"
          "source.sasl.jaas.config"                   = "software.amazon.msk.auth.iam.IAMLoginModule required;"
          "source.sasl.mechanism"                     = "AWS_MSK_IAM"
          "source.security.protocol"                  = "SASL_SSL"
          "source.ssl.truststore.location"            = "/usr/lib/jvm/java-11-amazon-corretto/lib/security/cacerts"
          "source.ssl.truststore.password"            = "changeit"
          "source.topic"                              = var.FLINK_APP_ENVIRONMENT_VARIABLES["SOURCE_TOPIC_NAME"]
        }
      }
    }

    application_snapshot_configuration {
      snapshots_enabled = var.FLINK_APP_SNAPSHOTS_ENABLED
    }

    application_code_configuration {
      code_content {
        s3_content_location {
          bucket_arn = "arn:aws:s3:::${var.FLINK_S3_BUCKET}"
          file_key   = var.FLINK_S3_FILE_KEY
        }
      }
      code_content_type = var.CODE_CONTENT_TYPE
    }

    vpc_configuration {
      subnet_ids         = [local.PRIVATE_SUBNET1_ID, local.PRIVATE_SUBNET2_ID, local.PRIVATE_SUBNET3_ID]
      security_group_ids = [local.MSK_SECURITY_GROUP]
    }
  }
}
