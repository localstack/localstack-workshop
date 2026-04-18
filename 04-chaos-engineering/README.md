# Module 04 — Chaos Engineering

Inject faults into LocalStack to simulate real-world failure scenarios, then verify that the system handles them gracefully via retries and dead-letter queues.

---

## Scenario: DynamoDB at Capacity

We'll simulate a `ProvisionedThroughputExceededException` on the `orders` table, causing the `order_processor` Lambda to fail. The SQS queue's redrive policy will retry 3 times before routing the message to the **Dead Letter Queue**.

---

## Step 1 — Inject the Fault

LocalStack's Fault Injection Simulator (FIS) API lets you force specific AWS errors:

```bash
# Inject DynamoDB throttling (50% error rate on UpdateItem)
awslocal fis create-experiment-template --cli-input-json file://faults/ddb-throttle.json
TEMPLATE_ID=$(awslocal fis list-experiment-templates --query 'experimentTemplates[0].id' --output text)
awslocal fis start-experiment --experiment-template-id $TEMPLATE_ID
```

Or use the LocalStack chaos API directly:

```bash
curl -s -X POST http://localhost:4566/_localstack/chaos/faults \
  -H "Content-Type: application/json" \
  -d @faults/ddb-throttle-localstack.json
```

---

## Step 2 — Send Orders and Watch Them Fail

```bash
API=$(cd ../01-serverless-app/terraform && tflocal output -raw api_endpoint)

# Send several orders
for i in {1..5}; do
  curl -s -X POST "$API/orders" \
    -H "Content-Type: application/json" \
    -d "{\"item\": \"chaos-item-$i\", \"quantity\": 1}" | python3 -m json.tool
done

# Watch DLQ fill up (wait ~30s for retries to exhaust)
sleep 30
awslocal sqs get-queue-attributes \
  --queue-url http://localhost:4566/000000000000/orders-dlq \
  --attribute-names ApproximateNumberOfMessages
```

You should see messages accumulating in the DLQ.

---

## Step 3 — Check DynamoDB State

Orders are written by `order_handler` (succeeds), but never reach `processed` status because `order_processor` keeps failing:

```bash
awslocal dynamodb scan --table-name orders \
  --filter-expression "#s = :p" \
  --expression-attribute-names '{"#s": "status"}' \
  --expression-attribute-values '{":p": {"S": "pending"}}'
```

---

## Step 4 — Remove the Fault and Replay

```bash
# Stop the fault injection
curl -s -X DELETE http://localhost:4566/_localstack/chaos/faults

# Manually replay DLQ messages back to the main queue
MAIN_QUEUE=http://localhost:4566/000000000000/orders-queue
DLQ=http://localhost:4566/000000000000/orders-dlq

# Receive from DLQ and re-send to main queue
awslocal sqs receive-message --queue-url $DLQ --max-number-of-messages 10 | \
  python3 04-chaos-engineering/scripts/replay_dlq.py
```

---

## Step 5 — Verify Recovery

```bash
sleep 15  # give Lambda time to process
awslocal dynamodb scan --table-name orders \
  --filter-expression "#s = :p" \
  --expression-attribute-names '{"#s": "status"}' \
  --expression-attribute-values '{":p": {"S": "processed"}}' \
  --query 'Count'
```

---

Next: [Module 05 — App Inspector](../05-app-inspector/README.md)
