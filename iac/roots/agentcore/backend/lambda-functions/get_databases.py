# Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import boto3
import json
import traceback


def lambda_handler(event, context):
    """
    Returns the list of Glue databases.
    """
    try:
        athena_client = boto3.client('athena')

        response = athena_client.list_databases(CatalogName='AwsDataCatalog')

        result = list()

        for record in response['DatabaseList']:
            name = record['Name']
            if name != 'default' or not name.startswith('glue_db_'):
                result.append(name)

        return {
            'statusCode': 200,
            'body': json.dumps(result, indent=2, default=str)
        }

    except Exception as e:
        stack_trace_string = traceback.format_exc()
        print(f"Error returning the list of glue databases: {stack_trace_string}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(stack_trace_string)})
        }
