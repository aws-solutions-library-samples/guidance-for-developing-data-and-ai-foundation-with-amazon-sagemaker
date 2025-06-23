# Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import sys
import logging
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.conf import SparkConf  

# Configure simple logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

args = getResolvedOptions(sys.argv, ['JOB_NAME', 'SOURCE_FILE', 'NAMESPACE', 'TABLE_BUCKET_ARN'])

SOURCE_FILE= args.get('SOURCE_FILE')
NAMESPACE = args.get("NAMESPACE")
TABLE_BUCKET_ARN = args.get("TABLE_BUCKET_ARN")

# Spark configuration for S3 Tables
conf = SparkConf()
conf.set("spark.sql.defaultCatalog", "s3tablescatalog")
conf.set("spark.sql.catalog.s3tablescatalog", "org.apache.iceberg.spark.SparkCatalog")
conf.set("spark.sql.catalog.s3tablescatalog.catalog-impl", "software.amazon.s3tables.iceberg.S3TablesCatalog")
conf.set("spark.sql.catalog.s3tablescatalog.io-impl", "org.apache.iceberg.aws.s3.S3FileIO")
conf.set("spark.sql.catalog.s3tablescatalog.warehouse", TABLE_BUCKET_ARN)
conf.set("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")

sc = SparkContext(conf=conf)
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

logger.info(f"Processing file: {SOURCE_FILE}")

try:
    
    # Read the source file
    logger.info("Reading source CSV file...")
    source_df = spark.read.csv(SOURCE_FILE, header=True)
    row_count = source_df.count()
    logger.info(f"Loaded {row_count} rows from source file")
    
    # Register as temp view
    source_df.createOrReplaceTempView("temp_billing")
    
    # Use the fully qualified table name with catalog
    target_table = f"s3tablescatalog.{NAMESPACE}.billing"
    
    # Try to insert data
    logger.info(f"Writing to S3 Table {target_table}")
    try:
        spark.sql(f"""
            INSERT INTO {target_table}
            SELECT * FROM temp_billing
            """)
    except Exception as e:
        logger.error(f"Error inserting data: {str(e)}")
        raise e

except Exception as e:
    logger.error(f"Error processing data: {str(e)}")
    raise e
finally:
    # Always commit the job
    job.commit()
    logger.info("Job completed")
