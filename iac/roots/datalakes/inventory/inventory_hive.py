# Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import sys
import logging
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import *

# Configure simple logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize the Glue context
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

# Enable Hive support and configurations
spark.conf.set("spark.sql.sources.partitionOverwriteMode", "dynamic")
spark.conf.set("spark.sql.hive.convertMetastoreParquet", "true")
spark.conf.set("hive.exec.dynamic.partition", "true")
spark.conf.set("hive.exec.dynamic.partition.mode", "nonstrict")
spark.conf.set("spark.sql.legacy.allowNonEmptyLocationInCTAS", "true")

job = Job(glueContext)

# Arguments for the Glue job
args = getResolvedOptions(
    sys.argv,
    [
        'JOB_NAME',
        'SOURCE_FILE',
        'DATABASE_NAME',
        'TABLE_NAME'
    ]
)

SOURCE_FILE = args.get("SOURCE_FILE")
DATABASE_NAME = args.get("DATABASE_NAME")
TABLE_NAME = args.get("TABLE_NAME")

logger.info(f"Processing file: {SOURCE_FILE}")
logger.info(f"Target Table: {DATABASE_NAME}.{TABLE_NAME}")

job.init(args['JOB_NAME'], args)

try:
    # Read the source file
    logger.info("Reading source CSV file...")
    source_df = spark.read.csv(SOURCE_FILE, header=True, inferSchema=True)
    row_count = source_df.count()
    logger.info(f"Loaded {row_count} rows from source file")
    
    # Write to Hive table
    logger.info("Writing data to Hive table...")
    source_df.createOrReplaceTempView('temp')

    spark.sql(f'USE {DATABASE_NAME}')
    spark.sql(f"""
            INSERT INTO {TABLE_NAME}
            SELECT * FROM temp
            """)
    
    logger.info(f"Successfully wrote {row_count} rows to Hive table {DATABASE_NAME}.{TABLE_NAME}")

except Exception as e:
    logger.error(f"Error processing data: {str(e)}")
    raise e
finally:
    # Always commit the job
    job.commit()
    logger.info("Job completed")
