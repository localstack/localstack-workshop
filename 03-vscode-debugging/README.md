# Module 03 — Lambda Debugging with VS Code AWS Toolkit

Set breakpoints in Lambda functions and step through them live — even though they run inside LocalStack.

---

## Prerequisites

- VS Code with the [AWS Toolkit extension](https://marketplace.visualstudio.com/items?itemName=AmazonWebServices.aws-toolkit-vscode) installed
- LocalStack running with the app deployed (module 01)

---

## Setup

1. Open this repo in VS Code
2. Open the **AWS Toolkit** panel (left sidebar, AWS icon)
3. Connect to LocalStack:
   - Click **Add a connection** → **Use IAM credentials**
   - Profile: use `localstack` profile or set region `us-east-1`, key `test`, secret `test`
   - Endpoint override: `http://localhost:4566`

---

## Start a Debug Session

The `.vscode/launch.json` in this module pre-configures a debug session for `order-handler`.

1. Open `../01-serverless-app/lambdas/order_handler/handler.py`
2. Set a breakpoint on the `table.put_item(...)` line
3. In VS Code: **Run → Start Debugging** (or F5) → select **"Debug order-handler (LocalStack)"**
4. Trigger the function:
   ```bash
   API=$(cd ../01-serverless-app/terraform && tflocal output -raw api_endpoint)
   curl -X POST "$API/orders" -H "Content-Type: application/json" \
     -d '{"item": "debugged item", "quantity": 1}'
   ```
5. VS Code pauses at your breakpoint — inspect `order`, `body`, `order_id`

---

## What to Explore

- Inspect the `event` object to see the raw API Gateway request shape
- Modify `order["status"]` in the debug console and watch DynamoDB receive the change
- Step into `table.put_item()` to see the boto3 call in real time

---

## How It Works

LocalStack supports the [AWS Lambda remote debugging protocol](https://docs.localstack.cloud/user-guide/tools/lambda-debugger/). When `LAMBDA_REMOTE_DEBUGGING=1` is set, LocalStack pauses Lambda execution and exposes a debugpy port that VS Code attaches to.

```bash
# Enable debugging mode (already set in devcontainer)
export LAMBDA_REMOTE_DEBUGGING=1
localstack restart
```

---

Next: [Module 04 — Chaos Engineering](../04-chaos-engineering/README.md)
