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

SOURCE_FILE = args.get("SOURCE_FILE")
NAMESPACE = args.get("NAMESPACE")
TABLE_BUCKET_ARN = args.get("TABLE_BUCKET_ARN")

logger.info(f"Creating Configuration")

# Spark configuration for S3 Tables
conf = SparkConf()
conf.set("spark.sql.defaultCatalog", "s3tablescatalog")
conf.set("spark.sql.catalog.s3tablescatalog", "org.apache.iceberg.spark.SparkCatalog")
conf.set("spark.sql.catalog.s3tablescatalog.catalog-impl", "software.amazon.s3tables.iceberg.S3TablesCatalog")
conf.set("spark.sql.catalog.s3tablescatalog.io-impl", "org.apache.iceberg.aws.s3.S3FileIO")
conf.set("spark.sql.catalog.s3tablescatalog.warehouse", TABLE_BUCKET_ARN)
conf.set("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")

logger.info(f"Created Configuration")

sc = SparkContext(conf=conf)
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

try:
    
    # Read the source file
    logger.info("Reading source CSV file...")
    source_df = spark.read.csv(SOURCE_FILE, header=True, inferSchema=True)
    row_count = source_df.count()
    logger.info(f"Loaded {row_count} rows from source file")

    source_df.createOrReplaceTempView('temp_inventory')

    # Write to Iceberg table
    logger.info(f"Writing to S3Table")

    spark.sql(f"""
        INSERT INTO s3tablescatalog.{NAMESPACE}.inventory
        SELECT * FROM temp_inventory
        """)

    logger.info(f"Wrote to S3Table")

except Exception as e:
    logger.error(f"Error processing data: {str(e)}")
    raise e
finally:
    # Always commit the job
    job.commit()
    logger.info("Job completed")



