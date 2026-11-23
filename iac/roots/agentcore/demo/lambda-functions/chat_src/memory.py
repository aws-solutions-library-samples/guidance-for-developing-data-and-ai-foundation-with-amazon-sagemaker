# Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

"""AgentCore Memory helpers for session listing and message retrieval.

The Strands AgentCoreMemorySessionManager (used in chat.py) handles all
conversation persistence and context retrieval automatically. This module
only provides the helpers the UI sidebar needs: listing past sessions for
a user and loading the messages for a specific session.

Both helpers unwrap the JSON envelope that Strands wraps around each
message before storing it in AgentCore Memory.
"""

import json
import logging
import os
from concurrent.futures import ThreadPoolExecutor

import boto3

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

REGION = os.environ.get("DEPLOY_REGION", os.environ.get("AWS_REGION", "us-east-1"))
SSM_PREFIX = os.environ.get("SSM_PREFIX", "")

# Cap on events fetched per session, both for title derivation and history reload
MAX_EVENTS_PER_SESSION = 100

_ssm = boto3.client("ssm", region_name=REGION)
_data = boto3.client("bedrock-agentcore", region_name=REGION)
_memory_id = None


# ---------------------------------------------------------------------------
# Memory ID resolution (cached)
# ---------------------------------------------------------------------------

def get_memory_id():
    """Return the AgentCore Memory ID, resolving from env var or SSM on first call."""
    global _memory_id
    if not _memory_id:
        _memory_id = os.environ.get("MEMORY_ID") or _ssm.get_parameter(
            Name=f"{SSM_PREFIX}/memory-id", WithDecryption=True
        )["Parameter"]["Value"]
    return _memory_id


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

def _extract_message(payload):
    """Extract a {role, content} dict from an event payload, or None to skip.

    Skips events that contain only tool-use/tool-result data (no text content),
    which would otherwise render as empty bubbles.
    """
    conv = payload.get("conversational")
    if not conv:
        return None
    text = conv.get("content", {}).get("text", "")
    if not text:
        return None
    try:
        msg = json.loads(text).get("message", {})
        role = msg.get("role", "").lower()
        inner = "".join(c.get("text", "") for c in msg.get("content", []) if c.get("text"))
        if role in ("user", "assistant") and inner.strip():
            return {"role": role, "content": inner}
    except (ValueError, TypeError):
        role = conv.get("role", "").lower()
        if role in ("user", "assistant") and text.strip():
            return {"role": role, "content": text}
    return None


def _extract_user_text(payload):
    """Extract the user's message text from a payload, or None if not a user turn."""
    msg = _extract_message(payload)
    return msg["content"] if msg and msg["role"] == "user" else None


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def _fetch_session_title(actor_id, session_id):
    """Best-effort fetch of the first user message in a session, used as title."""
    try:
        events_resp = _data.list_events(
            memoryId=get_memory_id(),
            actorId=actor_id,
            sessionId=session_id,
            includePayloads=True,
            maxResults=MAX_EVENTS_PER_SESSION,
        )
        # list_events returns newest-first; reverse to find the FIRST user message
        for event in reversed(events_resp.get("events", [])):
            for item in event.get("payload", []):
                user_text = _extract_user_text(item)
                if user_text:
                    return user_text[:50]
    except Exception:
        logger.warning("Failed to fetch title for session %s", session_id, exc_info=True)
    return ""


def list_sessions(actor_id):
    """List past sessions for a user, with the first user message as the title.

    Title fetches are parallelized across sessions to keep sidebar load fast
    even when a user has many sessions.
    """
    try:
        resp = _data.list_sessions(
            memoryId=get_memory_id(),
            actorId=actor_id,
            maxResults=20,
        )
    except _data.exceptions.ResourceNotFoundException as e:
        # AgentCore Memory only knows an actor after that user's first event,
        # so a brand-new user has no sessions yet rather than an error. Any
        # other not-found (for example a wrong memory ID) is still raised.
        if "Actor" not in str(e):
            raise
        logger.info("No sessions yet for actor %s", actor_id)
        return []
    summaries = resp.get("sessionSummaries", [])
    if not summaries:
        return []

    session_ids = [s.get("sessionId") for s in summaries]
    # AgentCore Memory has no batch API for events; we'd otherwise need one
    # list_events call per session sequentially. Run them in parallel threads
    # since each call is independent network I/O. Sidebar load drops from
    # O(N * latency) to roughly O(latency) for N <= 10 sessions.
    with ThreadPoolExecutor(max_workers=10) as executor:
        titles = list(executor.map(lambda sid: _fetch_session_title(actor_id, sid), session_ids))

    return [
        {
            "session_id": s.get("sessionId"),
            "title": title,
            "created_at": s.get("createdAt"),
        }
        for s, title in zip(summaries, titles)
    ]


def load_session_messages(actor_id, session_id):
    """Load conversation turns for a session, in chronological order.

    Collapses consecutive assistant messages to only the last one, since the
    agent emits intermediate "thinking" messages between tool calls and we
    only want to display the final response after each user question.
    """
    resp = _data.list_events(
        memoryId=get_memory_id(),
        actorId=actor_id,
        sessionId=session_id,
        includePayloads=True,
        maxResults=MAX_EVENTS_PER_SESSION,
    )

    # list_events returns newest-first; reverse to chronological order
    raw = []
    for event in reversed(resp.get("events", [])):
        for item in event.get("payload", []):
            msg = _extract_message(item)
            if msg:
                raw.append(msg)

    # Collapse consecutive assistant messages to only the latest one
    messages = []
    for m in raw:
        if m["role"] == "assistant" and messages and messages[-1]["role"] == "assistant":
            messages[-1] = m
        else:
            messages.append(m)
    return messages
