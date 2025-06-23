// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

resource "aws_lakeformation_permissions" "billing_producer_default_catalog_database_permissions" {

  principal   = local.PRODUCER_ROLE
  permissions = ["DESCRIBE", "CREATE_TABLE", "ALTER", "DROP"]
  permissions_with_grant_option = ["DESCRIBE", "CREATE_TABLE", "ALTER", "DROP"]

  database {
    catalog_id = local.account_id
    name = "${var.APP}_${var.ENV}_billing"
  }
}

resource "aws_lakeformation_permissions" "billing_producer_default_catalog_hive_table_permissions" {

  principal   = local.PRODUCER_ROLE
  permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]
  permissions_with_grant_option = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]

  table {
    catalog_id    = local.account_id
    database_name = "${var.APP}_${var.ENV}_billing"
    name          = "${var.APP}_${var.ENV}_billing_hive"
  }
}

resource "aws_lakeformation_permissions" "billing_producer_default_catalog_iceberg_staic_table_permissions" {

  principal   = local.PRODUCER_ROLE
  permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]
  permissions_with_grant_option = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]

  table {
    catalog_id    = local.account_id
    database_name = "${var.APP}_${var.ENV}_billing"
    name          = "${var.APP}_${var.ENV}_billing_iceberg_static"
  }
}

resource "aws_lakeformation_permissions" "billing_producer_default_catalog_iceberg_dynamic_table_permissions" {

  principal   = local.PRODUCER_ROLE
  permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]
  permissions_with_grant_option = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]

  table {
    catalog_id    = local.account_id
    database_name = "${var.APP}_${var.ENV}_billing"
    name          = "${var.APP}_${var.ENV}_billing_iceberg_dynamic"
  }
}

# resource "aws_cloudformation_stack" "lf_admin_append" {
#   name = "${var.APP}-${var.ENV}-lf-admin-append"

#   template_body = jsonencode({
#     Resources = {
#       DataLakeSettings = {
#         Type = "AWS::LakeFormation::DataLakeSettings"
#         Properties = {
#           Admins = [
#             {
#               DataLakePrincipalIdentifier = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Domain-Owner"
#             },
#             {
#               DataLakePrincipalIdentifier = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Project-Owner"
#             }
#           ]
#           MutationType = "APPEND"
#         }
#       }
#     }
#   })

#   capabilities = ["CAPABILITY_NAMED_IAM"]
# }

# resource "aws_lakeformation_permissions" "billing_producer_s3tables_catalog_database_permissions" {

#   principal   = local.PRODUCER_ROLE
#   permissions = ["DESCRIBE", "CREATE_TABLE", "ALTER", "DROP"]

#   database {
#     catalog_id = "${local.account_id}:s3tablescatalog/${var.APP}_${var.ENV}-billing"
#     name = "${var.APP}"
#   }
#

# resource "aws_lakeformation_permissions" "billing_producer_s3tables_catalog_table_permissions" {

#   principal   = local.PRODUCER_ROLE
#   permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]

#   table {
#     catalog_id    = local.account_id
#     database_name = "${var.APP}"
#     name          = "billing"
#   }
# }

# Consumer Lake Formation Permissions
# resource "aws_lakeformation_permissions" "billing_consumer_default_catalog_database_permissions" {

#   principal   = local.CONSUMER_ROLE
#   permissions = ["DESCRIBE", "CREATE_TABLE", "ALTER", "DROP"]

#   database {
#     catalog_id = local.account_id
#     name = "${var.APP}_${var.ENV}_billing"
#   }
# }

# resource "aws_lakeformation_permissions" "billing_consumer_default_catalog_hive_table_permissions" {

#   principal   = local.CONSUMER_ROLE
#   permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]

#   table {
#     catalog_id    = local.account_id
#     database_name = "${var.APP}_${var.ENV}_billing"
#     name          = "${var.APP}_${var.ENV}_billing_hive"
#   }
# }

# resource "aws_lakeformation_permissions" "billing_consumer_default_catalog_iceberg_static_table_permissions" {

#   principal   = local.CONSUMER_ROLE
#   permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]

#   table {
#     catalog_id    = local.account_id
#     database_name = "${var.APP}_${var.ENV}_billing"
#     name          = "${var.APP}_${var.ENV}_billing_iceberg_static"
#   }
# }

# resource "aws_lakeformation_permissions" "billing_consumer_default_catalog_iceberg_dynamic_table_permissions" {

#   principal   = local.CONSUMER_ROLE
#   permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]

#   table {
#     catalog_id    = local.account_id
#     database_name = "${var.APP}_${var.ENV}_billing"
#     name          = "${var.APP}_${var.ENV}_billing_iceberg_dynamic"
#   }
# }

# resource "aws_lakeformation_permissions" "consumer_s3tables_catalog_database_permissions" {

#   principal   = local.CONSUMER_ROLE
#   permissions = ["DESCRIBE", "CREATE_TABLE", "ALTER", "DROP"]

#   database {
#     catalog_id = "${local.account_id}:s3tablescatalog/${var.APP}_${var.ENV}-billing"
#     name = "${var.APP}"
#   }
# }

# resource "aws_lakeformation_permissions" "consumer_s3tables_catalog_table_permissions" {

#   principal   = local.CONSUMER_ROLE
#   permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]

#   table {
#     catalog_id    = local.account_id
#     database_name = "${var.APP}"
#     name          = "billing"
#   }
# }


// INVENTORY

# Producer Lake Formation Permissions
resource "aws_lakeformation_permissions" "inventory_producer_default_catalog_database_permissions" {

  principal   = local.PRODUCER_ROLE
  permissions = ["DESCRIBE", "CREATE_TABLE", "ALTER", "DROP"]
  permissions_with_grant_option = ["DESCRIBE", "CREATE_TABLE", "ALTER", "DROP"]

  database {
    catalog_id = local.account_id
    name = "${var.APP}_${var.ENV}_inventory"
  }
}

resource "aws_lakeformation_permissions" "inventory_producer_default_catalog_hive_table_permissions" {

  principal   = local.PRODUCER_ROLE
  permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]
  permissions_with_grant_option = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]

  table {
    catalog_id    = local.account_id
    database_name = "${var.APP}_${var.ENV}_inventory"
    name          = "${var.APP}_${var.ENV}_inventory_hive"
  }
}

resource "aws_lakeformation_permissions" "inventory_producer_default_catalog_iceberg_static_table_permissions" {

  principal   = local.PRODUCER_ROLE
  permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]
  permissions_with_grant_option = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]

  table {
    catalog_id    = local.account_id
    database_name = "${var.APP}_${var.ENV}_inventory"
    name          = "${var.APP}_${var.ENV}_inventory_iceberg_static"
  }
}

resource "aws_lakeformation_permissions" "inventory_producer_default_catalog_iceberg_dynamic_table_permissions" {

  principal   = local.PRODUCER_ROLE
  permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]
  permissions_with_grant_option = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]

  table {
    catalog_id    = local.account_id
    database_name = "${var.APP}_${var.ENV}_inventory"
    name          = "${var.APP}_${var.ENV}_inventory_iceberg_dynamic"
  }
}

# resource "aws_lakeformation_permissions" "inventory_producer_s3tables_catalog_database_permissions" {

#   principal   = local.PRODUCER_ROLE
#   permissions = ["DESCRIBE", "CREATE_TABLE", "ALTER", "DROP"]

#   database {
#     catalog_id = "${local.account_id}:s3tablescatalog/${var.APP}_${var.ENV}-inventory"
#     name = "${var.APP}"
#   }
# }

# resource "aws_lakeformation_permissions" "inventory_producer_s3tables_catalog_table_permissions" {

#   principal   = local.PRODUCER_ROLE
#   permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]

#   table {
#     catalog_id    = local.account_id
#     database_name = "${var.APP}"
#     name          = "inventory"
#   }
# }

# Consumer Lake Formation Permissions
# resource "aws_lakeformation_permissions" "inventory_consumer_default_catalog_database_permissions" {

#   principal   = local.CONSUMER_ROLE
#   permissions = ["DESCRIBE", "CREATE_TABLE", "ALTER", "DROP"]

#   database {
#     catalog_id = local.account_id
#     name = "${var.APP}_${var.ENV}_inventory"
#   }
# }

# resource "aws_lakeformation_permissions" "inventory_consumer_default_catalog_hive_table_permissions" {

#   principal   = local.CONSUMER_ROLE
#   permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]

#   table {
#     catalog_id    = local.account_id
#     database_name = "${var.APP}_${var.ENV}_inventory"
#     name          = "${var.APP}_${var.ENV}_inventory_hive"
#   }
# }

# resource "aws_lakeformation_permissions" "inventory_consumer_default_catalog_iceberg_static_table_permissions" {

#   principal   = local.CONSUMER_ROLE
#   permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]

#   table {
#     catalog_id    = local.account_id
#     database_name = "${var.APP}_${var.ENV}_inventory"
#     name          = "${var.APP}_${var.ENV}_inventory_iceberg_static"
#   }
# }

# resource "aws_lakeformation_permissions" "inventory_consumer_default_catalog_iceberg_dynamic_table_permissions" {

#   principal   = local.CONSUMER_ROLE
#   permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]

#   table {
#     catalog_id    = local.account_id
#     database_name = "${var.APP}_${var.ENV}_inventory"
#     name          = "${var.APP}_${var.ENV}_inventory_iceberg_dynamic"
#   }
# }

# resource "aws_lakeformation_permissions" "inventory_consumer_s3tables_catalog_database_permissions" {

#   principal   = local.CONSUMER_ROLE
#   permissions = ["DESCRIBE", "CREATE_TABLE", "ALTER", "DROP"]

#   database {
#     catalog_id = "${local.account_id}:s3tablescatalog/${var.APP}_${var.ENV}-inventory"
#     name = "${var.APP}"
#   }
# }

# resource "aws_lakeformation_permissions" "inventory_consumer_s3tables_catalog_table_permissions" {

#   principal   = local.CONSUMER_ROLE
#   permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]

#   table {
#     catalog_id    = local.account_id
#     database_name = "${var.APP}"
#     name          = "inventory"
#   }
# }

// SPLUNK

# Producer Lake Formation Permissions
resource "aws_lakeformation_permissions" "splunk_producer_default_catalog_database_permissions" {

  principal   = local.PRODUCER_ROLE
  permissions = ["DESCRIBE", "CREATE_TABLE", "ALTER", "DROP"]
  permissions_with_grant_option = ["DESCRIBE", "CREATE_TABLE", "ALTER", "DROP"]

  database {
    catalog_id = local.account_id
    name = "${var.APP}_${var.ENV}_splunk"
  }
}

resource "aws_lakeformation_permissions" "splunk_producer_default_catalog_iceberg_table_permissions" {

  principal   = local.PRODUCER_ROLE
  permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]
  permissions_with_grant_option = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]

  table {
    catalog_id    = local.account_id
    database_name = "${var.APP}_${var.ENV}_splunk"
    name          = "${var.APP}_${var.ENV}_splunk_iceberg"
  }
}

# resource "aws_lakeformation_permissions" "splunk_producer_s3tables_catalog_database_permissions" {

#   principal   = local.PRODUCER_ROLE
#   permissions = ["DESCRIBE", "CREATE_TABLE", "ALTER", "DROP"]

#   database {
#     catalog_id = "${local.account_id}:s3tablescatalog/${var.APP}_${var.ENV}-splunk"
#     name = "${var.APP}"
#   }
# }

# resource "aws_lakeformation_permissions" "inventory_producer_s3tables_catalog_table_permissions" {

#   principal   = local.PRODUCER_ROLE
#   permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]

#   table {
#     catalog_id    = local.account_id
#     database_name = "${var.APP}"
#     name          = "inventory"
#   }
# }

# Consumer Lake Formation Permissions
# resource "aws_lakeformation_permissions" "splunk_consumer_default_catalog_database_permissions" {

#   principal   = local.CONSUMER_ROLE
#   permissions = ["DESCRIBE", "CREATE_TABLE", "ALTER", "DROP"]

#   database {
#     catalog_id = local.account_id
#     name = "${var.APP}_${var.ENV}_splunk"
#   }
# }

# resource "aws_lakeformation_permissions" "splunk_consumer_default_catalog_iceberg_table_permissions" {

#   principal   = local.CONSUMER_ROLE
#   permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]

#   table {
#     catalog_id    = local.account_id
#     database_name = "${var.APP}_${var.ENV}_splunk"
#     name          = "${var.APP}_${var.ENV}_splunk_iceberg"
#   }
# }

# resource "aws_lakeformation_permissions" "splunk_consumer_s3tables_catalog_database_permissions" {

#   principal   = local.CONSUMER_ROLE
#   permissions = ["DESCRIBE", "CREATE_TABLE", "ALTER", "DROP"]

#   database {
#     catalog_id = "${local.account_id}:s3tablescatalog/${var.APP}_${var.ENV}-splunk"
#     name = "${var.APP}"
#   }
# }

# resource "aws_lakeformation_permissions" "splunk_consumer_s3tables_catalog_table_permissions" {

#   principal   = local.CONSUMER_ROLE
#   permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]

#   table {
#     catalog_id    = local.account_id
#     database_name = "${var.APP}"
#     name          = "splunk"
#   }
# }

resource "aws_lakeformation_permissions" "zetl_ddb_default_catalog_database_permissions" {

  principal   = local.PRODUCER_ROLE
  permissions = ["DESCRIBE", "CREATE_TABLE", "ALTER", "DROP"]
  permissions_with_grant_option = ["DESCRIBE", "CREATE_TABLE", "ALTER", "DROP"]

  database {
    catalog_id = local.account_id
    name = "${var.APP}_${var.ENV}_equity_orders_zetl_ddb"
  }
}

resource "aws_lakeformation_permissions" "zetl_ddb_default_catalog_table_permissions" {

  principal   = local.PRODUCER_ROLE
  permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]
  permissions_with_grant_option = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]

  table {
    catalog_id    = local.account_id
    database_name = "${var.APP}_${var.ENV}_equity_orders_zetl_ddb"
    name          = "${var.APP}_${var.ENV}_equity_orders_db_table"
  }
}

resource "aws_lakeformation_permissions" "price_producer_default_catalog_database_permissions" {

  principal   = local.PRODUCER_ROLE
  permissions = ["DESCRIBE", "CREATE_TABLE", "ALTER", "DROP"]
  permissions_with_grant_option = ["DESCRIBE", "CREATE_TABLE", "ALTER", "DROP"]

  database {
    catalog_id = local.account_id
    name = "${var.APP}_${var.ENV}_price"
  }
}

resource "aws_lakeformation_permissions" "price_producer_default_catalog_hive_table_permissions" {

  principal   = local.PRODUCER_ROLE
  permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]
  permissions_with_grant_option = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]

  table {
    catalog_id    = local.account_id
    database_name = "${var.APP}_${var.ENV}_price"
    name          = "${var.APP}_${var.ENV}_price_hive"
  }
}

resource "aws_lakeformation_permissions" "price_producer_default_catalog_iceberg_table_permissions" {

  principal   = local.PRODUCER_ROLE
  permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]
  permissions_with_grant_option = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]

  table {
    catalog_id    = local.account_id
    database_name = "${var.APP}_${var.ENV}_price"
    name          = "${var.APP}_${var.ENV}_price_iceberg"
  }
}

resource "aws_lakeformation_permissions" "trade_producer_default_catalog_database_permissions" {

  principal   = local.PRODUCER_ROLE
  permissions = ["DESCRIBE", "CREATE_TABLE", "ALTER", "DROP"]
  permissions_with_grant_option = ["DESCRIBE", "CREATE_TABLE", "ALTER", "DROP"]

  database {
    catalog_id = local.account_id
    name = "${var.APP}_${var.ENV}_trade"
  }
}

resource "aws_lakeformation_permissions" "trade_producer_default_catalog_hive_table_permissions" {

  principal   = local.PRODUCER_ROLE
  permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]
  permissions_with_grant_option = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]

  table {
    catalog_id    = local.account_id
    database_name = "${var.APP}_${var.ENV}_trade"
    name          = "${var.APP}_${var.ENV}_trade_hive"
  }
}

resource "aws_lakeformation_permissions" "trade_producer_default_catalog_iceberg_table_permissions" {

  principal   = local.PRODUCER_ROLE
  permissions = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]
  permissions_with_grant_option = ["SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"]

  table {
    catalog_id    = local.account_id
    database_name = "${var.APP}_${var.ENV}_trade"
    name          = "${var.APP}_${var.ENV}_trade_iceberg"
  }
}