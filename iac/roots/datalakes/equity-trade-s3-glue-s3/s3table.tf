// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_kms_key" "s3tables_kms_key" {

  key_id = "alias/${var.S3_TABLES_KMS_KEY_ALIAS}"
}

resource "aws_s3tables_table_bucket" "equity_trade" {

  name = "equity-trade-s3-glue-s3table"

  encryption_configuration = {
    sse_algorithm = "aws:kms"
    kms_key_arn   = data.aws_kms_key.s3tables_kms_key.arn
  }
}

resource "aws_s3tables_namespace" "equity_trade" {

  namespace        = var.APP
  table_bucket_arn = aws_s3tables_table_bucket.equity_trade.arn
}

module "equity_trade" {

  source = "../../../templates/modules/s3-table-iceberg"

  BUCKET_ARN = aws_s3tables_table_bucket.equity_trade.arn
  NAMESPACE  = aws_s3tables_namespace.equity_trade.namespace
  TABLE_NAME = "equity_trade_s3_glue_s3table"

  FIELDS = [
    {
      name     = "order_id"
      type     = "string"
      required = true
    },
    {
      name     = "trade_id"
      type     = "string"
      required = true
    },
    {
      name     = "account_id"
      type     = "string"
      required = true
    },
    {
      name     = "security_id"
      type     = "string"
      required = true
    },
    {
      name     = "side"
      type     = "string"
      required = true
    },
    {
      name     = "quantity"
      type     = "string"
      required = true
    },
    {
      name     = "price"
      type     = "string"
      required = true
    },
    {
      name     = "execution_time"
      type     = "string"
      required = true
    },
    {
      name     = "fee"
      type     = "string"
      required = true
    },
    {
      name     = "commission"
      type     = "string"
      required = true
    }
  ]
}

data "aws_iam_policy_document" "equity_trade_bucket_policy_document" {

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
      "${aws_s3tables_table_bucket.equity_trade.arn}/*",
      aws_s3tables_table_bucket.equity_trade.arn
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
      "${aws_s3tables_table_bucket.equity_trade.arn}/*",
      aws_s3tables_table_bucket.equity_trade.arn
    ]
  }
}

resource "aws_s3tables_table_bucket_policy" "equity_trade_policy" {

  resource_policy  = data.aws_iam_policy_document.equity_trade_bucket_policy_document.json
  table_bucket_arn = aws_s3tables_table_bucket.equity_trade.arn
}