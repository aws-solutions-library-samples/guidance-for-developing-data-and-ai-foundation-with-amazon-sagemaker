// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# ---------------------------------------------------------------------------
# S3 bucket for Lambda deployment packages
# ---------------------------------------------------------------------------

module "lambda_bucket" {
  source = "../../../templates/modules/bucket"

  APP     = var.APP
  ENV     = var.ENV
  NAME    = "agentcore-lambda"
  USAGE   = "agentcore-lambda"
  CMK_ARN = module.lambda_kms_key.arn
}

# ---------------------------------------------------------------------------
# ZIP archives
# ---------------------------------------------------------------------------

data "archive_file" "get_databases" {
  type        = "zip"
  source_file = "${path.module}/lambda-functions/get_databases.py"
  output_path = "${path.module}/lambda-functions/get_databases.zip"
}

data "archive_file" "get_database_tables" {
  type        = "zip"
  source_file = "${path.module}/lambda-functions/get_database_tables.py"
  output_path = "${path.module}/lambda-functions/get_database_tables.zip"
}

data "archive_file" "execute_query" {
  type        = "zip"
  source_file = "${path.module}/lambda-functions/execute_query.py"
  output_path = "${path.module}/lambda-functions/execute_query.zip"
}

data "archive_file" "web_search" {
  type        = "zip"
  source_file = "${path.module}/lambda-functions/web_search.py"
  output_path = "${path.module}/lambda-functions/web_search.zip"
}

# ---------------------------------------------------------------------------
# Upload ZIPs to S3
# ---------------------------------------------------------------------------

resource "aws_s3_object" "get_databases" {
  bucket = module.lambda_bucket.bucket_id
  key    = "get_databases.zip"
  source = data.archive_file.get_databases.output_path
  etag   = data.archive_file.get_databases.output_md5
  #checkov:skip=CKV_AWS_186: "Ensure S3 bucket Object is encrypted by KMS using a customer managed Key (CMK)"
}

resource "aws_s3_object" "get_database_tables" {
  bucket = module.lambda_bucket.bucket_id
  key    = "get_database_tables.zip"
  source = data.archive_file.get_database_tables.output_path
  etag   = data.archive_file.get_database_tables.output_md5
  #checkov:skip=CKV_AWS_186: "Ensure S3 bucket Object is encrypted by KMS using a customer managed Key (CMK)"
}

resource "aws_s3_object" "execute_query" {
  bucket = module.lambda_bucket.bucket_id
  key    = "execute_query.zip"
  source = data.archive_file.execute_query.output_path
  etag   = data.archive_file.execute_query.output_md5
  #checkov:skip=CKV_AWS_186: "Ensure S3 bucket Object is encrypted by KMS using a customer managed Key (CMK)"
}

resource "aws_s3_object" "web_search" {
  bucket = module.lambda_bucket.bucket_id
  key    = "web_search.zip"
  source = data.archive_file.web_search.output_path
  etag   = data.archive_file.web_search.output_md5
  #checkov:skip=CKV_AWS_186: "Ensure S3 bucket Object is encrypted by KMS using a customer managed Key (CMK)"
}

# ---------------------------------------------------------------------------
# Lambda functions
# ---------------------------------------------------------------------------

resource "aws_lambda_function" "get_databases" {
  #checkov:skip=CKV_AWS_116: "DLQ not needed for agent tool"
  #checkov:skip=CKV_AWS_173: "Env vars not sensitive"
  #checkov:skip=CKV_AWS_272: "Code signing not required"

  function_name = "${var.APP}-${var.ENV}-get-databases"
  description   = "Returns the list of Glue databases via Athena"
  role          = aws_iam_role.agentcore_lambda_role.arn
  handler       = "get_databases.lambda_handler"
  runtime       = "python3.13"
  timeout       = 60
  memory_size   = 256
  publish       = true

  s3_bucket        = module.lambda_bucket.bucket_id
  s3_key           = aws_s3_object.get_databases.key
  source_code_hash = data.archive_file.get_databases.output_base64sha256

  kms_key_arn                    = module.lambda_kms_key.arn
  reserved_concurrent_executions = 3

  tracing_config {
    mode = "Active"
  }

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "agentcore"
  }
}

resource "aws_lambda_function" "get_database_tables" {
  #checkov:skip=CKV_AWS_116: "DLQ not needed for agent tool"
  #checkov:skip=CKV_AWS_173: "Env vars not sensitive"
  #checkov:skip=CKV_AWS_272: "Code signing not required"

  function_name = "${var.APP}-${var.ENV}-get-database-tables"
  description   = "Returns table schemas from a Glue database, filtered to iceberg tables"
  role          = aws_iam_role.agentcore_lambda_role.arn
  handler       = "get_database_tables.lambda_handler"
  runtime       = "python3.13"
  timeout       = 60
  memory_size   = 256
  publish       = true

  s3_bucket        = module.lambda_bucket.bucket_id
  s3_key           = aws_s3_object.get_database_tables.key
  source_code_hash = data.archive_file.get_database_tables.output_base64sha256

  kms_key_arn                    = module.lambda_kms_key.arn
  reserved_concurrent_executions = 3

  tracing_config {
    mode = "Active"
  }

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "agentcore"
  }
}

resource "aws_lambda_function" "execute_query" {
  #checkov:skip=CKV_AWS_116: "DLQ not needed for agent tool"
  #checkov:skip=CKV_AWS_173: "Env vars not sensitive"
  #checkov:skip=CKV_AWS_272: "Code signing not required"

  function_name = "${var.APP}-${var.ENV}-execute-query"
  description   = "Executes a SQL query against a Glue table using Athena"
  role          = aws_iam_role.agentcore_lambda_role.arn
  handler       = "execute_query.lambda_handler"
  runtime       = "python3.13"
  timeout       = 60
  memory_size   = 256
  publish       = true

  s3_bucket        = module.lambda_bucket.bucket_id
  s3_key           = aws_s3_object.execute_query.key
  source_code_hash = data.archive_file.execute_query.output_base64sha256

  kms_key_arn                    = module.lambda_kms_key.arn
  reserved_concurrent_executions = 3

  environment {
    variables = {
      ATHENA_OUTPUT_BUCKET = "s3://${local.athena_output_bucket}/"
      ATHENA_WORKGROUP     = local.athena_workgroup
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "agentcore"
  }
}

resource "aws_lambda_function" "web_search" {
  #checkov:skip=CKV_AWS_116: "DLQ not needed for agent tool"
  #checkov:skip=CKV_AWS_173: "Env vars not sensitive"
  #checkov:skip=CKV_AWS_272: "Code signing not required"

  function_name = "${var.APP}-${var.ENV}-web-search"
  description   = "Searches the web using DuckDuckGo for updated information"
  role          = aws_iam_role.agentcore_lambda_role.arn
  handler       = "web_search.lambda_handler"
  runtime       = "python3.13"
  timeout       = 60
  memory_size   = 256
  publish       = true

  s3_bucket        = module.lambda_bucket.bucket_id
  s3_key           = aws_s3_object.web_search.key
  source_code_hash = data.archive_file.web_search.output_base64sha256

  kms_key_arn                    = module.lambda_kms_key.arn
  reserved_concurrent_executions = 3

  layers = [aws_lambda_layer_version.ddgs.arn]

  tracing_config {
    mode = "Active"
  }

  tags = {
    Application = var.APP
    Environment = var.ENV
    Usage       = "agentcore"
  }
}

# ---------------------------------------------------------------------------
# Lambda layer for ddgs (DuckDuckGo Search) dependency
#
# The build is triggered by the hash of ddgs-requirements.txt, which pins the
# dependency version. The layer is rebuilt and republished only when that file
# changes, so applies stay idempotent and layer versions do not accumulate.
#
# ddgs-requirements.txt sits outside the ddgs/ directory on purpose, since
# that directory is what gets archived into the layer.
# ---------------------------------------------------------------------------

resource "null_resource" "ddgs_layer_build" {
  triggers = {
    requirements = filemd5("${path.module}/lambda-layers/ddgs-requirements.txt")
  }

  provisioner "local-exec" {
    command = <<-EOT
      rm -rf ${path.module}/lambda-layers/ddgs/python
      mkdir -p ${path.module}/lambda-layers/ddgs/python
      pip3 install -r ${path.module}/lambda-layers/ddgs-requirements.txt \
        -t ${path.module}/lambda-layers/ddgs/python -q \
        --platform manylinux2014_x86_64 --python-version 3.13 --only-binary=:all:
    EOT
  }
}

data "archive_file" "ddgs_layer" {
  type        = "zip"
  source_dir  = "${path.module}/lambda-layers/ddgs"
  output_path = "${path.module}/lambda-layers/ddgs.zip"
  depends_on  = [null_resource.ddgs_layer_build]
}

resource "aws_lambda_layer_version" "ddgs" {
  layer_name          = "${var.APP}-${var.ENV}-ddgs"
  filename            = data.archive_file.ddgs_layer.output_path
  source_code_hash    = data.archive_file.ddgs_layer.output_base64sha256
  compatible_runtimes = ["python3.13"]
}
