# Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import json
from ddgs import DDGS
from ddgs.exceptions import DDGSException, RatelimitException


def lambda_handler(event, context):
    print(f"EVENT: {json.dumps(event, default=str)}")

    # Support both flat object (MCP gateway) and parameters array (Bedrock Agent)
    if "parameters" in event and isinstance(event["parameters"], list):
        params = {p["name"]: p["value"] for p in event["parameters"]}
    else:
        params = event

    keywords = params.get("keywords", "")
    max_results = int(params.get("max_results", "5"))

    try:
        results = DDGS().text(keywords, region="us-en", max_results=max_results)
        return {"statusCode": 200, "body": json.dumps(results if results else "No results found.")}
    except RatelimitException:
        return {"statusCode": 429, "body": json.dumps("Rate limit reached. Please try again later.")}
    except (DDGSException, Exception) as e:
        return {"statusCode": 500, "body": json.dumps(f"Search error: {e}")}
