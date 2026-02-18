// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_kms_key" "s3tables_kms_key" {

  key_id = "alias/${var.S3_TABLES_KMS_KEY_ALIAS}"
}

resource "aws_s3tables_table_bucket" "billing" {

  name = "finops-billing-s3-glue-s3table"

  encryption_configuration = {
    sse_algorithm = "aws:kms"
    kms_key_arn   = data.aws_kms_key.s3tables_kms_key.arn
  }
}

resource "aws_s3tables_namespace" "billing" {

  namespace        = var.APP
  table_bucket_arn = aws_s3tables_table_bucket.billing.arn
}

module "billing" {

  source = "../../../templates/modules/s3-table-iceberg"

  BUCKET_ARN = aws_s3tables_table_bucket.billing.arn
  NAMESPACE  = aws_s3tables_namespace.billing.namespace
  TABLE_NAME = "finops_billing_s3_glue_s3table"

  FIELDS = [
    {
      name     = "identity_line_item_id"
      type     = "string"
      required = false
    },
    {
      name     = "identity_time_interval"
      type     = "string"
      required = false
    },
    {
      name     = "bill_invoice_id"
      type     = "string"
      required = false
    },
    {
      name     = "bill_invoicing_entity"
      type     = "string"
      required = false
    },
    {
      name     = "bill_billing_entity"
      type     = "string"
      required = false
    },
    {
      name     = "bill_bill_type"
      type     = "string"
      required = false
    },
    {
      name     = "bill_payer_account_id"
      type     = "string"
      required = false
    },
    {
      name     = "bill_billing_period_start_date"
      type     = "string"
      required = false
    },
    {
      name     = "bill_billing_period_end_date"
      type     = "string"
      required = false
    },
    {
      name     = "line_item_usage_account_id"
      type     = "string"
      required = false
    },
    {
      name     = "line_item_line_item_type"
      type     = "string"
      required = false
    },
    {
      name     = "line_item_usage_start_date"
      type     = "string"
      required = false
    },
    {
      name     = "line_item_usage_end_date"
      type     = "string"
      required = false
    },
    {
      name     = "line_item_product_code"
      type     = "string"
      required = false
    },
    {
      name     = "line_item_usage_type"
      type     = "string"
      required = false
    },
    {
      name     = "line_item_operation"
      type     = "string"
      required = false
    },
    {
      name     = "line_item_availability_zone"
      type     = "string"
      required = false
    },
    {
      name     = "line_item_resource_id"
      type     = "string"
      required = false
    },
    {
      name     = "line_item_usage_amount"
      type     = "string"
      required = false
    },
    {
      name     = "line_item_normalization_factor"
      type     = "string"
      required = false
    },
    {
      name     = "line_item_normalized_usage_amount"
      type     = "string"
      required = false
    },
    {
      name     = "line_item_currency_code"
      type     = "string"
      required = false
    },
    {
      name     = "line_item_unblended_rate"
      type     = "string"
      required = false
    },
    {
      name     = "line_item_unblended_cost"
      type     = "string"
      required = false
    },
    {
      name     = "line_item_blended_rate"
      type     = "string"
      required = false
    },
    {
      name     = "line_item_blended_cost"
      type     = "string"
      required = false
    },
    {
      name     = "line_item_line_item_description"
      type     = "string"
      required = false
    },
    {
      name     = "line_item_tax_type"
      type     = "string"
      required = false
    },
    {
      name     = "line_item_legal_entity"
      type     = "string"
      required = false
    },
    {
      name     = "product_product_name"
      type     = "string"
      required = false
    },
    {
      name     = "product_availability"
      type     = "string"
      required = false
    },
    {
      name     = "product_category"
      type     = "string"
      required = false
    },
    {
      name     = "product_ci_type"
      type     = "string"
      required = false
    },
    {
      name     = "product_cloud_formation_resource_provider"
      type     = "string"
      required = false
    },
    {
      name     = "product_description"
      type     = "string"
      required = false
    },
    {
      name     = "product_durability"
      type     = "string"
      required = false
    },
    {
      name     = "product_endpoint_type"
      type     = "string"
      required = false
    },
    {
      name     = "product_event_type"
      type     = "string"
      required = false
    },
    {
      name     = "product_fee_code"
      type     = "string"
      required = false
    },
    {
      name     = "product_fee_description"
      type     = "string"
      required = false
    },
    {
      name     = "product_free_query_types"
      type     = "string"
      required = false
    },
    {
      name     = "product_from_location"
      type     = "string"
      required = false
    },
    {
      name     = "product_from_location_type"
      type     = "string"
      required = false
    },
    {
      name     = "product_from_region_code"
      type     = "string"
      required = false
    },
    {
      name     = "product_group"
      type     = "string"
      required = false
    },
    {
      name     = "product_group_description"
      type     = "string"
      required = false
    },
    {
      name     = "product_location"
      type     = "string"
      required = false
    },
    {
      name     = "product_location_type"
      type     = "string"
      required = false
    },
    {
      name     = "product_logs_destination"
      type     = "string"
      required = false
    },
    {
      name     = "product_message_delivery_frequency"
      type     = "string"
      required = false
    },
    {
      name     = "product_message_delivery_order"
      type     = "string"
      required = false
    },
    {
      name     = "product_operation"
      type     = "string"
      required = false
    },
    {
      name     = "product_plato_pricing_type"
      type     = "string"
      required = false
    },
    {
      name     = "product_product_family"
      type     = "string"
      required = false
    },
    {
      name     = "product_queue_type"
      type     = "string"
      required = false
    },
    {
      name     = "product_region"
      type     = "string"
      required = false
    },
    {
      name     = "product_region_code"
      type     = "string"
      required = false
    },
    {
      name     = "product_request_type"
      type     = "string"
      required = false
    },
    {
      name     = "product_service_code"
      type     = "string"
      required = false
    },
    {
      name     = "product_service_name"
      type     = "string"
      required = false
    },
    {
      name     = "product_sku"
      type     = "string"
      required = false
    },
    {
      name     = "product_storage_class"
      type     = "string"
      required = false
    },
    {
      name     = "product_storage_media"
      type     = "string"
      required = false
    },
    {
      name     = "product_to_location"
      type     = "string"
      required = false
    },
    {
      name     = "product_to_location_type"
      type     = "string"
      required = false
    },
    {
      name     = "product_to_region_code"
      type     = "string"
      required = false
    },
    {
      name     = "product_transfer_type"
      type     = "string"
      required = false
    },
    {
      name     = "product_usage_type"
      type     = "string"
      required = false
    },
    {
      name     = "product_version"
      type     = "string"
      required = false
    },
    {
      name     = "product_volume_type"
      type     = "string"
      required = false
    },
    {
      name     = "pricing_rate_code"
      type     = "string"
      required = false
    },
    {
      name     = "pricing_rate_id"
      type     = "string"
      required = false
    },
    {
      name     = "pricing_currency"
      type     = "string"
      required = false
    },
    {
      name     = "pricing_public_on_demand_cost"
      type     = "string"
      required = false
    },
    {
      name     = "pricing_public_on_demand_rate"
      type     = "string"
      required = false
    },
    {
      name     = "pricing_term"
      type     = "string"
      required = false
    },
    {
      name     = "pricing_unit"
      type     = "string"
      required = false
    },
    {
      name     = "reservation_amortized_upfront_cost_for_usage"
      type     = "string"
      required = false
    },
    {
      name     = "reservation_amortized_upfront_fee_for_billing_period"
      type     = "string"
      required = false
    },
    {
      name     = "reservation_effective_cost"
      type     = "string"
      required = false
    },
    {
      name     = "reservation_end_time"
      type     = "string"
      required = false
    },
    {
      name     = "reservation_modification_status"
      type     = "string"
      required = false
    },
    {
      name     = "reservation_normalized_units_per_reservation"
      type     = "string"
      required = false
    },
    {
      name     = "reservation_number_of_reservations"
      type     = "string"
      required = false
    },
    {
      name     = "reservation_recurring_fee_for_usage"
      type     = "string"
      required = false
    },
    {
      name     = "reservation_start_time"
      type     = "string"
      required = false
    },
    {
      name     = "reservation_subscription_id"
      type     = "string"
      required = false
    },
    {
      name     = "reservation_total_reserved_normalized_units"
      type     = "string"
      required = false
    },
    {
      name     = "reservation_total_reserved_units"
      type     = "string"
      required = false
    },
    {
      name     = "reservation_units_per_reservation"
      type     = "string"
      required = false
    },
    {
      name     = "reservation_unused_amortized_upfront_fee_for_billing_period"
      type     = "string"
      required = false
    },
    {
      name     = "reservation_unused_normalized_unit_quantity"
      type     = "string"
      required = false
    },
    {
      name     = "reservation_unused_quantity"
      type     = "string"
      required = false
    },
    {
      name     = "reservation_unused_recurring_fee"
      type     = "string"
      required = false
    },
    {
      name     = "reservation_upfront_value"
      type     = "string"
      required = false
    },
    {
      name     = "savings_plan_total_commitment_to_date"
      type     = "string"
      required = false
    },
    {
      name     = "savings_plan_savings_plan_arn"
      type     = "string"
      required = false
    },
    {
      name     = "savings_plan_savings_plan_rate"
      type     = "string"
      required = false
    },
    {
      name     = "savings_plan_used_commitment"
      type     = "string"
      required = false
    },
    {
      name     = "savings_plan_savings_plan_effective_cost"
      type     = "string"
      required = false
    },
    {
      name     = "savings_plan_amortized_upfront_commitment_for_billing_period"
      type     = "string"
      required = false
    },
    {
      name     = "savings_plan_recurring_commitment_for_billing_period"
      type     = "string"
      required = false
    },
    {
      name     = "resource_tags_user_application"
      type     = "string"
      required = false
    },
    {
      name     = "resource_tags_user_environment"
      type     = "string"
      required = false
    },
    {
      name     = "resource_tags_user_usage"
      type     = "string"
      required = false
    }
  ]
}

data "aws_iam_policy_document" "billing_bucket_policy_document" {

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
      "${aws_s3tables_table_bucket.billing.arn}/*",
      aws_s3tables_table_bucket.billing.arn
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
      "${aws_s3tables_table_bucket.billing.arn}/*",
      aws_s3tables_table_bucket.billing.arn
    ]
  }
}

resource "aws_s3tables_table_bucket_policy" "billing_policy" {

  resource_policy  = data.aws_iam_policy_document.billing_bucket_policy_document.json
  table_bucket_arn = aws_s3tables_table_bucket.billing.arn
}
