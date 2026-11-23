# Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

"""DAIVI agent Lambda handler.

Serves the static UI on GET /, and handles chat/session actions on POST /chat.
Uses Strands' AgentCoreMemorySessionManager for stateful conversations backed
by Amazon Bedrock AgentCore Memory.
"""

import json
import logging
import os
import uuid
from datetime import datetime, timezone

import boto3
import requests
from bedrock_agentcore.memory.integrations.strands.config import (
    AgentCoreMemoryConfig,
    RetrievalConfig,
)
from bedrock_agentcore.memory.integrations.strands.session_manager import (
    AgentCoreMemorySessionManager,
)
from mcp.client.streamable_http import streamablehttp_client
from strands import Agent
from strands.models.bedrock import BedrockModel
from strands.tools.mcp import MCPClient

import memory

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

REGION = os.environ.get("DEPLOY_REGION", os.environ.get("AWS_REGION", "us-east-1"))
SSM_PREFIX = os.environ["SSM_PREFIX"]

MODELS = {
    "nova": "us.amazon.nova-2-lite-v1:0",
    "haiku": "us.anthropic.claude-haiku-4-5-20251001-v1:0",
}

# Output token budget per model call, large enough for a formatted multi-row
# answer without hitting MaxTokensReachedException. Both models above accept
# this value.
MAX_TOKENS = 8192

SYSTEM_PROMPT = """Today's date is {date}.

You are DAIVI, a helpful financial analyst assistant proficient with executing database queries.
Your role is to:
- Provide accurate information using the tools available to you
- First get the list of databases available, then get the schema of the relevant tables
  before writing a query
- Execute queries against the relevant databases and tables
- Be friendly, patient, and professional
- Always offer additional help after answering questions

Data guidance:
- Your databases contain historical equity trade and stock price data. Questions about
  trades, prices, symbols, accounts or volumes refer to this data unless the user
  explicitly asks for live or current market prices.
- For any such question, check the databases first. Use web search only for information
  the databases cannot contain, such as news, or when the user asks for it.
- If the user asks for "latest" or "recent" values, use the most recent records in the
  data and say they are as of that record's timestamp.
- If the user does not name specific symbols or accounts, choose a small sample yourself
  (for example 5) and answer in a single query rather than asking which ones.
- Always use the tools to get accurate information rather than making assumptions.
- Answer only from data that exists in the available tables. If a question asks for data
  that no table contains (for example holdings or positions), say that the data is not
  available and describe the data that is. Do not compute, derive, or estimate it from a
  different table, and do not treat missing data as zero. Holdings and positions in
  particular must not be calculated from trades, including as a sum or net of buys and
  sells.

Query guidance:
- Prefer the *_iceberg table in each database.
- Select only the columns needed to answer rather than SELECT *, and summarize the
  results instead of repeating every field of every row.
- If a query fails with a storage or permission error (for example HIVE_FILESYSTEM_ERROR
  or AccessDenied), do not retry the same query. Report the error and suggest another
  table instead. Each retry adds several seconds and requests time out after 30 seconds.

You have access to the following tools:
1. databases___get-databases() - Returns the list of databases
2. tables___get-database-tables() - Returns the schema for the tables in the database specified
3. query___execute-query() - Executes the query against the database specified
4. web-search___web-search() - Searches the web for current information using keywords"""

ssm = boto3.client("ssm", region_name=REGION)
cognito = boto3.client("cognito-idp", region_name=REGION)

# MCP client is cached across warm Lambda invocations to avoid reconnecting
_mcp_client = None


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _get_ssm(name):
    """Fetch a SecureString SSM parameter under SSM_PREFIX."""
    return ssm.get_parameter(Name=f"{SSM_PREFIX}/{name}", WithDecryption=True)["Parameter"]["Value"]


def _get_user_email(event):
    """Extract the authenticated user's email from the JWT claims."""
    claims = event.get("requestContext", {}).get("authorizer", {}).get("jwt", {}).get("claims", {})
    return claims.get("email", claims.get("sub", "anonymous"))


def _sanitize_actor_id(email):
    """Convert email to a valid AgentCore Memory actor_id.

    AgentCore Memory enforces the regex [a-zA-Z0-9][a-zA-Z0-9-_/]* on actor_id.
    Emails contain @ and . which are not allowed, so we substitute them.
    See https://docs.aws.amazon.com/bedrock-agentcore/latest/APIReference/API_ActorSummary.html
    """
    return email.replace("@", "_at_").replace(".", "_")


def _get_model(model_key="nova"):
    """Return a BedrockModel for the given key, defaulting to Nova 2 Lite."""
    model_id = MODELS.get(model_key, MODELS["nova"])
    return BedrockModel(model_id=model_id, region_name=REGION, max_tokens=MAX_TOKENS)


# ---------------------------------------------------------------------------
# MCP gateway initialization (cached per warm Lambda)
# ---------------------------------------------------------------------------

def _init_mcp_client():
    """Authenticate with Cognito and connect the MCP client to the gateway."""
    global _mcp_client

    pool_id = _get_ssm("cognito-user-pool-id")
    client_id = _get_ssm("cognito-app-client-id")
    gateway_url = _get_ssm("gateway-url")

    app = cognito.describe_user_pool_client(UserPoolId=pool_id, ClientId=client_id)["UserPoolClient"]
    client_secret = app["ClientSecret"]
    domain = cognito.describe_user_pool(UserPoolId=pool_id)["UserPool"]["Domain"]
    scope = app["AllowedOAuthScopes"][0]

    token_resp = requests.post(
        f"https://{domain}.auth.{REGION}.amazoncognito.com/oauth2/token",
        data={
            "grant_type": "client_credentials",
            "client_id": client_id,
            "client_secret": client_secret,
            "scope": scope,
        },
        headers={"Content-Type": "application/x-www-form-urlencoded"},
    )
    token_resp.raise_for_status()
    access_token = token_resp.json()["access_token"]

    _mcp_client = MCPClient(
        lambda: streamablehttp_client(
            gateway_url,
            headers={"Authorization": f"Bearer {access_token}"},
        )
    )
    _mcp_client.start()


# ---------------------------------------------------------------------------
# Lambda handler
# ---------------------------------------------------------------------------

def lambda_handler(event, context):
    """Route incoming requests: GET / serves UI, POST /chat handles agent actions."""
    try:
        method = event.get("requestContext", {}).get("http", {}).get("method", "")
        if method == "GET":
            return _serve_ui()
        return _handle_post(event)
    except Exception:
        logger.exception("Lambda handler failed")
        # Reset cached client on error so the next invocation reconnects cleanly
        global _mcp_client
        _mcp_client = None
        return _server_error("Internal error, check CloudWatch logs")


def _serve_ui():
    """Serve the static chat UI from S3."""
    s3 = boto3.client("s3")
    bucket = os.environ.get("SITE_BUCKET", "")
    obj = s3.get_object(Bucket=bucket, Key="index.html")
    html = obj["Body"].read().decode("utf-8")
    return {"statusCode": 200, "headers": {"Content-Type": "text/html"}, "body": html}


def _handle_post(event):
    """Handle a POST /chat request: dispatch by action to chat or sidebar handlers."""
    global _mcp_client
    if _mcp_client is None:
        _init_mcp_client()

    body = json.loads(event.get("body", "{}"))
    action = body.get("action", "chat")
    user_id = _get_user_email(event)
    actor_id = _sanitize_actor_id(user_id)

    # Sidebar actions (read-only queries against AgentCore Memory)
    if action == "list_sessions":
        return _ok({"sessions": memory.list_sessions(actor_id)})
    if action == "load_session":
        return _ok({"messages": memory.load_session_messages(actor_id, body["session_id"])})

    # Default action: chat with the agent
    return _handle_chat(body, actor_id)


def _handle_chat(body, actor_id):
    """Run the Strands agent against the user's prompt with AgentCore Memory."""
    prompt = body.get("prompt", "")
    session_id = body.get("session_id", "")
    model_key = body.get("model", "nova")

    if not prompt:
        return _bad_request("prompt is required")

    # Empty session_id means a new conversation; generate a fresh ID
    if not session_id:
        session_id = str(uuid.uuid4())[:8]

    # Configure AgentCore Memory for this user + session.
    # The session manager auto-loads prior turns, persists new turns, and
    # retrieves relevant LTM context (preferences, facts, summaries).
    memory_config = AgentCoreMemoryConfig(
        memory_id=memory.get_memory_id(),
        session_id=session_id,
        actor_id=actor_id,
        retrieval_config={
            "/preferences/{actorId}/": RetrievalConfig(top_k=5, relevance_score=0.5),
            "/facts/{actorId}/": RetrievalConfig(top_k=5, relevance_score=0.3),
            "/summaries/{actorId}/{sessionId}/": RetrievalConfig(top_k=3, relevance_score=0.5),
        },
    )

    # Context manager flushes buffered messages on exit (success or error)
    with AgentCoreMemorySessionManager(
        agentcore_memory_config=memory_config,
        region_name=REGION,
    ) as session_manager:
        agent = Agent(
            model=_get_model(model_key),
            tools=_mcp_client.list_tools_sync(),
            system_prompt=SYSTEM_PROMPT.format(
                date=datetime.now(timezone.utc).strftime("%Y-%m-%d"),
            ),
            session_manager=session_manager,
        )
        response = agent(prompt)

    return _ok({"response": str(response), "session_id": session_id})


# ---------------------------------------------------------------------------
# Response helpers
# ---------------------------------------------------------------------------

def _ok(data):
    return {"statusCode": 200, "headers": _cors(), "body": json.dumps(data, default=str)}


def _bad_request(message):
    return {"statusCode": 400, "headers": _cors(), "body": json.dumps({"error": message})}


def _server_error(message):
    return {"statusCode": 500, "headers": _cors(), "body": json.dumps({"error": message})}


def _cors():
    return {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": os.environ["ALLOWED_ORIGIN"],
        "Access-Control-Allow-Headers": "Content-Type,Authorization",
        "Access-Control-Allow-Methods": "POST,OPTIONS",
    }
