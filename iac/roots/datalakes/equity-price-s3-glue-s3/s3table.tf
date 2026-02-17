// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_kms_key" "s3tables_kms_key" {

  key_id = "alias/${var.S3_TABLES_KMS_KEY_ALIAS}"
}

resource "aws_s3tables_table_bucket" "equity_price" {

  name = "equity-price-s3-glue-s3table"

  encryption_configuration = {
    sse_algorithm = "aws:kms"
    kms_key_arn   = data.aws_kms_key.s3tables_kms_key.arn
  }
}

resource "aws_s3tables_namespace" "equity_price" {

  namespace        = var.APP
  table_bucket_arn = aws_s3tables_table_bucket.equity_price.arn
}

module "equity_price" {

  source = "../../../templates/modules/s3-table-iceberg"

  BUCKET_ARN = aws_s3tables_table_bucket.equity_price.arn
  NAMESPACE  = aws_s3tables_namespace.equity_price.namespace
  TABLE_NAME = "equity_price_s3_glue_s3table"

  FIELDS = [
    {
      name     = "message_type"
      type     = "string"
      required = true
    },
    {
      name     = "timestamp"
      type     = "string"
      required = true
    },
    {
      name     = "symbol"
      type     = "string"
      required = true
    },
    {
      name     = "market_center"
      type     = "string"
      required = true
    },
    {
      name     = "open_close_indicator"
      type     = "string"
      required = true
    },
    {
      name     = "price"
      type     = "string"
      required = true
    }
  ]
}

data "aws_iam_policy_document" "equity_price_bucket_policy_document" {

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
      "${aws_s3tables_table_bucket.equity_price.arn}/*",
      aws_s3tables_table_bucket.equity_price.arn
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
      "${aws_s3tables_table_bucket.equity_price.arn}/*",
      aws_s3tables_table_bucket.equity_price.arn
    ]
  }
}

resource "aws_s3tables_table_bucket_policy" "equity_price_policy" {

  resource_policy  = data.aws_iam_policy_document.equity_price_bucket_policy_document.json
  table_bucket_arn = aws_s3tables_table_bucket.equity_price.arn
}
