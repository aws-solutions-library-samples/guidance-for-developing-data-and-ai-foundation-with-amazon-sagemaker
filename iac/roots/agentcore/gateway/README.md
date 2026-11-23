# AgentCore Gateway

A pure MCP tool server that exposes Lambda-backed tools over the MCP protocol with Cognito JWT authentication. Clients bring their own LLM agent and system prompt — the gateway handles auth and tool routing only.

## Prerequisites

The following must be deployed **before** the gateway:

| Dependency | Makefile target | What it provides |
|---|---|---|
| Terraform backend | `deploy-tf-backend-cf-stack` | S3 + DynamoDB for remote state |
| AgentCore backend | `deploy-agentcore-backend` | Cognito, Lambda functions, AgentCore IAM role, and the SSM parameters the gateway reads at plan time |

The AgentCore backend has its own prerequisites, including the equity price and equity trade data
lakes. See [Prerequisites](../README.md#prerequisites) in the module README.

The backend publishes these SSM parameters that the gateway depends on:

- `/<APP>/<ENV>/agentcore/cognito-user-pool-id`
- `/<APP>/<ENV>/agentcore/cognito-app-client-id`
- `/<APP>/<ENV>/agentcore/cognito-endpoint`
- `/<APP>/<ENV>/agentcore/agent-core-role-arn`
- `/<APP>/<ENV>/agentcore/lambda-get-databases-arn`
- `/<APP>/<ENV>/agentcore/lambda-get-database-tables-arn`
- `/<APP>/<ENV>/agentcore/lambda-execute-query-arn`
- `/<APP>/<ENV>/agentcore/lambda-web-search-arn`

## Tools Exposed

| Tool | Description |
|---|---|
| `get-databases` | Returns the list of Glue databases |
| `get-database-tables` | Returns table schemas for a given database |
| `execute-query` | Executes a SQL query and returns results |
| `web-search` | Searches the web for current information |

## Adding a New Tool

All tools are defined in `local.tools` in `main.tf`. To add a new tool:

1. Deploy the Lambda in the backend and publish its ARN to SSM
2. Add an entry to `local.tools` in `main.tf`:
   ```hcl
   my_tool = {
     ssm_key     = "lambda-my-tool-arn"
     name        = "my-tool"
     description = "What the tool does"
     properties  = [
       { name = "param1", type = "string", required = true }
     ]
   }
   ```
3. Run `make deploy-agentcore-gateway` — the target is generated automatically via `for_each`

## Resources Created

| Resource | File | Purpose |
|---|---|---|
| AgentCore MCP Gateway | `gateway.tf` | MCP endpoint with Cognito JWT auth |
| Gateway Targets (×4) | `targets.tf` | Generated from `local.tools` via `for_each` — one per tool |
| SSM Parameter | `outputs.tf` | Publishes `gateway-url` for downstream consumers |

## File Overview

| File | Description |
|---|---|
| `main.tf` | `local.tools` registry (single source of truth), SSM lookups, shared tags |
| `gateway.tf` | AgentCore gateway resource with MCP protocol and Cognito JWT auth |
| `targets.tf` | Single `for_each` block that generates all gateway targets from `local.tools` |
| `outputs.tf` | SSM parameter export and Terraform outputs |
| `variables.tf` | Input variable declarations |
| `backend.tf` | Remote S3 state configuration |
| `provider.tf` | AWS provider and version constraints |
| `terraform.tfvars` | Variable assignments (populated by `init.sh`) |

## Deploy / Destroy

```bash
# Deploys backend, gateway, then demo
make deploy-agentcore

# Or individually, in order
make deploy-agentcore-backend
make deploy-agentcore-gateway

# Tears down demo, gateway, then backend
make destroy-agentcore
```

## Testing

Deploy the demo UI to test the gateway end-to-end:

```bash
make deploy-agentcore-demo

# Demo URL, and the temporary password for the demo user daivi-agent@example.com
make get-agentcore-demo-url
make get-agentcore-demo-password
```

This deploys an S3 + API Gateway + Lambda chat interface that connects a client-side Strands agent to the MCP gateway. Open the URL from `make get-agentcore-demo-url` and sign in as `daivi-agent@example.com` with the temporary password; you will be prompted to set a new one.

### Prerequisites

- Backend and gateway deployed (`make deploy-agentcore-backend` and `make deploy-agentcore-gateway`)
- The equity price and equity trade data lakes deployed and loaded (`make deploy-price-glue-all` and `make deploy-trade-glue-all`), since those are the tables the agent can query
