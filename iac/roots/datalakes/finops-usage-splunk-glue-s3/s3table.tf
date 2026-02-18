// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_kms_key" "s3tables_kms_key" {

  key_id = "alias/${var.S3_TABLES_KMS_KEY_ALIAS}"
}

resource "aws_s3tables_table_bucket" "splunk" {

  name = "finops-usage-splunk-glue-s3table"

  encryption_configuration = {
    sse_algorithm = "aws:kms"
    kms_key_arn   = data.aws_kms_key.s3tables_kms_key.arn
  }
}

resource "aws_s3tables_namespace" "splunk" {

  namespace        = var.APP
  table_bucket_arn = aws_s3tables_table_bucket.splunk.arn
}

module "splunk" {

  source = "../../../templates/modules/s3-table-iceberg"

  BUCKET_ARN = aws_s3tables_table_bucket.splunk.arn
  NAMESPACE  = aws_s3tables_namespace.splunk.namespace
  TABLE_NAME = "finops_usage_splunk_glue_s3table"

  FIELDS = [
    {
      name     = "_time"
      type     = "string"
      required = false
    },
    {
      name     = "host"
      type     = "string"
      required = false
    },
    {
      name     = "source"
      type     = "string"
      required = false
    },
    {
      name     = "sourcetype"
      type     = "string"
      required = false
    }
  ]
}

data "aws_iam_policy_document" "splunk_bucket_policy_document" {

  statement {
    sid    = "AllowAthenaAccess"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["athena.amazonaws.com"]
    }

    actions = [
      "s3tables:*"
    ]

    resources = [
      "${aws_s3tables_table_bucket.splunk.arn}/*",
      aws_s3tables_table_bucket.splunk.arn
    ]
  }

  statement {
    sid    = "AllowGlueAccess"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }

    actions = [
      "s3tables:*"
    ]

    resources = [
      "${aws_s3tables_table_bucket.splunk.arn}/*",
      aws_s3tables_table_bucket.splunk.arn
    ]
  }
}

resource "aws_s3tables_table_bucket_policy" "splunk_policy" {

  resource_policy  = data.aws_iam_policy_document.splunk_bucket_policy_document.json
  table_bucket_arn = aws_s3tables_table_bucket.splunk.arn
}
