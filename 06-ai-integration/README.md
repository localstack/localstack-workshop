# Module 06 — AI Integration *(optional, ~10 min)*

Use AI tooling to interact with your local AWS environment — no cloud credentials needed.

---

## Option A — LocalStack MCP Server

The LocalStack MCP server exposes your local AWS resources to AI assistants (Claude, Cursor, etc.) via the [Model Context Protocol](https://modelcontextprotocol.io).

### Setup (Claude Code / Claude Desktop)

Add to your MCP config (`~/.claude/claude_desktop_config.json` or `.mcp.json`):

```json
{
  "mcpServers": {
    "localstack": {
      "command": "localstack",
      "args": ["mcp", "start"]
    }
  }
}
```

### What You Can Ask

Once connected, ask Claude natural-language questions about your local stack:

```
"List all Lambda functions and their last invocation status"
"Show me the messages in the orders-dlq queue"
"Scan the orders DynamoDB table and summarize the order statuses"
"What's in the order-receipts S3 bucket?"
```

---

## Option B — LocalStack Skills (Claude Code)

Claude Code ships with built-in LocalStack skills. With LocalStack running, try:

```
/localstack          # manage LocalStack lifecycle
/localstack-logs     # analyze logs and debug errors
/localstack-state    # save/load state with Cloud Pods
/localstack-iam      # analyze IAM policies
```

### Example: Debug a Lambda Error

1. Trigger a Lambda failure (e.g., send a malformed order payload)
2. Run `/localstack-logs` in Claude Code
3. Claude will fetch the Lambda logs and suggest a fix

---

## Option C — Claude Code + App Inspector

Combine App Inspector traces with Claude Code for AI-assisted debugging:

1. Find a failed trace in App Inspector
2. Copy the trace ID
3. Ask Claude:
   ```
   "Here's a failed trace from App Inspector: <trace-id>
    The order-processor Lambda failed. Analyze the logs and suggest what went wrong."
   ```

---

## Why This Matters

- No cloud credentials exposure to AI tools — everything stays local
- AI can read real state, not mocked data
- Fast iteration: ask → inspect → fix → redeploy in seconds locally
