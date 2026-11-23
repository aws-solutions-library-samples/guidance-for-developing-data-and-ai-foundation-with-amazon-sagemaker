# Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import boto3
import json
import os
import re
import time
import traceback

# The agent only needs to read data, so statements are limited to read-only
# forms. This stops a prompt from making Athena write to S3 (UNLOAD, INSERT,
# CTAS) or change tables. Lake Formation SELECT-only grants and the Athena
# output-only S3 policy enforce the same boundary; this check rejects such
# statements before they reach Athena.
_READ_ONLY_START = re.compile(r"^\s*(SELECT|WITH|SHOW|DESCRIBE)\b", re.IGNORECASE)
_WRITE_KEYWORDS = re.compile(
    r"\b(UNLOAD|INSERT|UPDATE|DELETE|MERGE|CREATE|DROP|ALTER|OPTIMIZE|VACUUM|MSCK)\b",
    re.IGNORECASE,
)


def is_read_only(query):
    """Return True if the query is a single read-only statement."""
    if not isinstance(query, str):
        return False
    statement = query.strip().rstrip(";")
    # A single statement only, so "SELECT 1; DROP TABLE t" is rejected.
    if ";" in statement:
        return False
    return bool(_READ_ONLY_START.match(statement)) and not _WRITE_KEYWORDS.search(statement)


def lambda_handler(event, context):
    """
    Executes a read-only SQL query against an AWS Glue table using Athena.
    """
    athena_client = boto3.client('athena')

    # Parameterized via Lambda environment variables
    output_location = os.environ.get('ATHENA_OUTPUT_BUCKET')
    workgroup = os.environ.get('ATHENA_WORKGROUP', 'primary')

    database = get_named_parameter(event=event, name="database")
    query = get_named_parameter(event=event, name="query")

    print(database)
    print(query)

    if not is_read_only(query):
        print("Rejected query that is not a single read-only statement")
        return {
            'statusCode': 400,
            'body': json.dumps({
                'error': 'Only a single read-only statement (SELECT, WITH, SHOW or DESCRIBE) is allowed.'
            })
        }

    try:
        response = athena_client.start_query_execution(
            QueryString=query,
            QueryExecutionContext={
                'Database': database
            },
            WorkGroup=workgroup,
            ResultConfiguration={
                'OutputLocation': output_location
            }
        )

        query_execution_id = response['QueryExecutionId']
        print(f"Athena query started with ID: {query_execution_id}")

        while True:
            query_status = athena_client.get_query_execution(
                QueryExecutionId=query_execution_id
            )
            state = query_status['QueryExecution']['Status']['State']

            if state in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
                break
            time.sleep(5)

        if state == 'SUCCEEDED':
            print(f"Athena query {query_execution_id} SUCCEEDED.")
            get_results_response = athena_client.get_query_results(
                QueryExecutionId=query_execution_id
            )

            records = list()

            if ('ResultSet' in get_results_response
                    and 'Rows' in get_results_response['ResultSet']):

                columns = list()
                rows = get_results_response['ResultSet']['Rows']
                first = True
                for row in rows:
                    record = {}
                    if first:
                        first_row_data = row['Data']
                        for entry in first_row_data:
                            columns.append(entry['VarCharValue'])
                        first = False
                    else:
                        row_data = row['Data']
                        index = 0
                        for entry in row_data:
                            record[columns[index]] = entry['VarCharValue']
                            index = index + 1
                        records.append(record)

            return {
                'statusCode': 200,
                'body': json.dumps(records, indent=2, default=str)
            }

        # Query failed or was cancelled
        error_message = query_status['QueryExecution']['Status'].get(
            'StateChangeReason', 'Unknown error'
        )
        print(f"Athena query {query_execution_id} {state}: {error_message}")
        return {
            'statusCode': 500,
            'body': f"Query {query_execution_id} {state}: {error_message}"
        }

    except Exception as e:
        stack_trace_string = traceback.format_exc()
        print(f"Error executing Athena query: {stack_trace_string}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(stack_trace_string)})
        }


def get_named_parameter(event, name):
    if name not in event:
        return None
    return event.get(name)
