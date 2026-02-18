// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_kms_key" "s3tables_kms_key" {

  key_id = "alias/${var.S3_TABLES_KMS_KEY_ALIAS}"
}

resource "aws_s3tables_table_bucket" "inventory" {

  name = "finops-inventory-s3-glue-s3table"

  encryption_configuration = {
    sse_algorithm = "aws:kms"
    kms_key_arn   = data.aws_kms_key.s3tables_kms_key.arn
  }
}

resource "aws_s3tables_namespace" "inventory" {

  namespace        = var.APP
  table_bucket_arn = aws_s3tables_table_bucket.inventory.arn
}

module "inventory" {

  source = "../../../templates/modules/s3-table-iceberg"

  BUCKET_ARN = aws_s3tables_table_bucket.inventory.arn
  NAMESPACE  = aws_s3tables_namespace.inventory.namespace
  TABLE_NAME = "finops_inventory_s3_glue_s3table"

  FIELDS = [
    {
      name     = "bucket"
      type     = "string"
      required = false
    },
    {
      name     = "key"
      type     = "string"
      required = false
    },
    {
      name     = "size"
      type     = "string"
      required = false
    },
    {
      name     = "last_modified_date"
      type     = "string"
      required = false
    },
    {
      name     = "etag"
      type     = "string"
      required = false
    },
    {
      name     = "storage_class"
      type     = "string"
      required = false
    },
    {
      name     = "is_multipart_uploaded"
      type     = "string"
      required = false
    },
    {
      name     = "replication_status"
      type     = "string"
      required = false
    },
    {
      name     = "encryption_status"
      type     = "string"
      required = false
    },
    {
      name     = "is_latest"
      type     = "string"
      required = false
    },
    {
      name     = "object_lock_mode"
      type     = "string"
      required = false
    },
    {
      name     = "object_lock_legal_hold_status"
      type     = "string"
      required = false
    },
    {
      name     = "bucket_key_status"
      type     = "string"
      required = false
    },
    {
      name     = "object_lock_retain_until_date"
      type     = "string"
      required = false
    },
    {
      name     = "checksum_algorithm"
      type     = "string"
      required = false
    },
    {
      name     = "object_access_control_list"
      type     = "string"
      required = false
    },
    {
      name     = "object_owner"
      type     = "string"
      required = false
    }
  ]
}

data "aws_iam_policy_document" "inventory_bucket_policy_document" {

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
      "${aws_s3tables_table_bucket.inventory.arn}/*",
      aws_s3tables_table_bucket.inventory.arn
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
      "${aws_s3tables_table_bucket.inventory.arn}/*",
      aws_s3tables_table_bucket.inventory.arn
    ]
  }
}

resource "aws_s3tables_table_bucket_policy" "inventory_policy" {

  resource_policy  = data.aws_iam_policy_document.inventory_bucket_policy_document.json
  table_bucket_arn = aws_s3tables_table_bucket.inventory.arn
}
