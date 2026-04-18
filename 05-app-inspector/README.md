# Module 05 — App Inspector

LocalStack App Inspector gives you a visual, real-time view of your serverless application: service topology, request traces, and event flows — without any instrumentation code.

---

## Open App Inspector

App Inspector is available in the LocalStack Web App:

1. Go to **https://app.localstack.cloud** → **App Inspector**
2. Select your LocalStack instance (should auto-detect if running locally)
3. You'll see the Order Processing Pipeline topology automatically discovered

---

## Topology View

After running module 01, App Inspector shows:

```
[API Gateway: orders-api]
    └─▶ [Lambda: order-handler]
            ├─▶ [DynamoDB: orders]
            └─▶ [SQS: orders-queue]
                    └─▶ [Lambda: order-processor]
                                ├─▶ [DynamoDB: orders]  (UpdateItem)
                                └─▶ [S3: order-receipts]
                    [SQS: orders-dlq]  ← (on failure)
```

---

## Trace the Happy Path

1. Send an order:
   ```bash
   API=$(cd ../01-serverless-app/terraform && tflocal output -raw api_endpoint)
   curl -X POST "$API/orders" -H "Content-Type: application/json" \
     -d '{"item": "inspector demo", "quantity": 1}'
   ```
2. In App Inspector → **Traces** tab, find the trace for your request
3. Click through to see: API GW → Lambda cold start → DynamoDB write → SQS publish → Lambda invocation → S3 put

---

## Trace the Chaos Scenario

1. Re-inject the DynamoDB fault (from module 04):
   ```bash
   curl -s -X POST http://localhost:4566/_localstack/chaos/faults \
     -H "Content-Type: application/json" \
     -d @../04-chaos-engineering/faults/ddb-throttle-localstack.json
   ```
2. Send a few orders
3. In App Inspector → **Traces**, look for failed traces (shown in red)
4. Expand a failed trace to see:
   - `order-processor` Lambda errored with `ProvisionedThroughputExceededException`
   - SQS retry count incrementing (visible in event metadata)
   - Message eventually routing to `orders-dlq`
5. Remove the fault and replay — watch the trace go green

---

## Key App Inspector Features to Explore

| Feature | Where |
|---------|-------|
| Service topology graph | **Overview** tab |
| Per-request traces | **Traces** tab |
| Lambda invocation logs | Click a Lambda node → **Logs** |
| SQS message flow | Click an SQS node → **Messages** |
| DynamoDB operations | Click DynamoDB node → **Operations** |

---

Next: [Module 06 — AI Integration](../06-ai-integration/README.md) *(optional)*
