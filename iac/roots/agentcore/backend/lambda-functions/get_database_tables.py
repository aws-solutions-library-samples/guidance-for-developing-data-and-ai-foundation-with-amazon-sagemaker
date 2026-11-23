# Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import boto3
import json
import traceback


def lambda_handler(event, context):
    """
    Returns the list of tables in a Glue database, filtered to iceberg tables.
    """
    try:
        athena_client = boto3.client('athena')

        database = get_named_parameter(event=event, name="database")

        response = athena_client.list_table_metadata(
            CatalogName='AwsDataCatalog', DatabaseName=database
        )

        result = list()

        for record in response['TableMetadataList']:
            name = record['Name']
            columns = record['Columns']
            if name.endswith("_iceberg"):
                result.append({'Table Name': name, 'Table Columns': columns})

        return {
            'statusCode': 200,
            'body': json.dumps(result, indent=2, default=str)
        }

    except Exception as e:
        stack_trace_string = traceback.format_exc()
        print(f"Error returning the list of glue tables: {stack_trace_string}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(stack_trace_string)})
        }


def get_named_parameter(event, name):
    if name not in event:
        return None
    return event.get(name)
