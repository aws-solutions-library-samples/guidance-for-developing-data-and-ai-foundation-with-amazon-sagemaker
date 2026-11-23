# AgentCore Demo

A chat application that lets users query financial data lakes and search the web using natural language. Built with a Strands AI agent connected to backend tools via an MCP gateway.

## How It Works

1. User types a question in the browser (e.g., "how many databases do I have?" or "who is the current president?")
2. API Gateway routes the request to the chat Lambda
3. The Lambda runs a **Strands agent** powered by **Amazon Nova 2 Lite** (default) or **Claude Haiku 4.5**
4. The model reads the question and decides which tool(s) to call
5. Tool calls go through the **Bedrock AgentCore MCP gateway**, which authenticates with Cognito and invokes the appropriate backend Lambda
6. Results flow back to the model, which formulates a natural language response
7. Response is returned to the browser

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│  Browser (index.html)                                            │
│  Login page → Cognito Hosted UI → Chat UI                        │
└──────────────┬───────────────────────────────────────────────────┘
               │ POST /chat {prompt: "..."} + Authorization: Bearer <JWT>
               ▼
┌──────────────────────────────────────────────────────────────────┐
│  API Gateway HTTP API                                            │
│  Routes: GET / → Lambda (no auth)                                │
│          POST /chat → JWT Authorizer → Lambda                    │
└──────────────┬───────────────────────────────────────────────────┘
               ▼
┌──────────────────────────────────────────────────────────────────┐
│  Demo Lambda (chat.py)                                           │
│                                                                  │
│  1. On cold start:                                               │
│     - Reads Cognito + gateway config from SSM                    │
│     - Obtains OAuth2 token via client_credentials grant          │
│     - Connects MCP client to the gateway with Bearer token       │
│                                                                  │
│  2. On each request:                                             │
│     - Fetches the tool list from the gateway (tools/list)        │
│     - Creates a Strands agent with the selected model, the       │
│       tools, and an AgentCore Memory session manager             │
│     - Session manager loads prior turns and relevant memories    │
│     - Agent decides which tools to call (model tool use)         │
│     - Tool calls → MCP gateway → backend Lambdas                 │
│     - Agent returns natural language response                    │
│     - Session manager saves the turn to AgentCore Memory         │
│                                                                  │
│  Cached across warm invocations: MCP client and its token        │
└──────────────┬───────────────────────────────────────────────────┘
               │ MCP tools/call (HTTPS + Bearer JWT)
               ▼
┌──────────────────────────────────────────────────────────────────┐
│  Bedrock AgentCore MCP Gateway                                   │
│  Auth: CUSTOM_JWT via Cognito                                    │
│                                                                  │
│  Tools:                                                          │
│  ├── get-databases      → {APP}-{ENV}-get-databases Lambda       │
│  ├── get-database-tables → {APP}-{ENV}-get-database-tables       │
│  ├── execute-query      → {APP}-{ENV}-execute-query              │
│  └── web-search         → {APP}-{ENV}-web-search                 │
└──────────────────────────────────────────────────────────────────┘
```

## Components

### Static UI (`static/index.html`)

Chat interface with Cognito Hosted UI login flow. On load, the page shows a "Sign In" button that
redirects to the Cognito Hosted UI. After authentication, the authorization code is exchanged for
tokens and the chat interface is displayed. The JWT token is attached to all `POST /chat` requests.
Terraform injects the API Gateway URL, Cognito domain, client ID, and redirect URI at deploy time
via `templatefile()`. Stored in S3 and served by the Lambda on `GET /`.

### Chat Lambda (`lambda-functions/chat_src/`)

- Runtime: Python 3.13
- Timeout: 120s (agent calls can chain multiple tools)
- Memory: 512 MB
- Layer: `strands-agents[mcp]`, `bedrock-agentcore[strands-agents]`, `requests`

Split into two modules:
- `chat.py` — handler, MCP client setup, action routing, agent creation with AgentCore Memory
- `memory.py` — sidebar helpers: list a user's sessions and load a session's messages

The MCP client is cached as a module-level global for warm invocations, and the agent is created per request with the selected model. On error, the cache is cleared so the next invocation re-initializes cleanly. Conversation memory is managed by the AgentCore Memory service, which automatically extracts preferences, facts, and session summaries.

### Lambda Layer

Built at deploy time from `lambda-functions/requirements.txt`. Uses `--platform manylinux2014_x86_64` to ensure native dependencies compile for Lambda's Amazon Linux runtime.

## Example Queries

- "How many databases do I have?" → calls `get-databases`
- "Show me the tables in the equity trade database" → calls `get-database-tables`
- "Which stocks were traded the most?" → calls `execute-query` with generated SQL
- "Who is the current president?" → calls `web-search`
- "What tables do I have and what's the latest news on AWS?" → chains multiple tools

## Deploy

```bash
# Prerequisites: backend and gateway must be deployed first
cd iac/roots/agentcore/demo
terraform init
terraform apply

# Demo URL, and the temporary password for the demo user daivi-agent@example.com (run from the repo root)
make get-agentcore-demo-url
make get-agentcore-demo-password
```

Outputs:
- `site_url` — chat UI (also available later with `make get-agentcore-demo-url`)
- `api_url` — POST endpoint for programmatic access

## Operational Notes

- **Cold starts**: First invocation takes 15-30s (Lambda init + Cognito auth + MCP handshake + tool discovery). Subsequent requests on warm instances take 3-15s depending on tool chain complexity.
- **Cache invalidation**: If the gateway is redeployed (new URL), update any env var on this Lambda to force a cold start. The Lambda reads the gateway URL from SSM on init, so it will pick up the new value.
- **Authentication**: `POST /chat` requires a valid Cognito JWT. The UI handles token acquisition automatically via the Cognito Hosted UI login flow. Tokens are stored in `sessionStorage` and cleared on sign out.
- **Demo credentials**: Sign in as `daivi-agent@example.com` with the temporary password from `make get-agentcore-demo-password` (SSM `/{APP}/{ENV}/agentcore/demo-user-temp-password`). It is only valid until the first sign-in, when you will be prompted to set a new password.
- **Self-registration disabled**: Only admin-created users can log in. To add users, create them in the Cognito user pool via the AWS Console or CLI.
