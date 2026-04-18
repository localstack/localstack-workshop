# Module 01 — Serverless App

Build intuition with the `awslocal` CLI, then deploy the full Order Processing Pipeline with Terraform.

---

## Part A — AWS CLI Basics with `awslocal`

### S3

```bash
# Create a bucket and upload a file
awslocal s3 mb s3://workshop-receipts
echo "hello localstack" > /tmp/test.txt
awslocal s3 cp /tmp/test.txt s3://workshop-receipts/test.txt
awslocal s3 ls s3://workshop-receipts
```

### DynamoDB

```bash
# Create a table and put an item
awslocal dynamodb create-table \
  --table-name orders-scratch \
  --attribute-definitions AttributeName=order_id,AttributeType=S \
  --key-schema AttributeName=order_id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

awslocal dynamodb put-item \
  --table-name orders-scratch \
  --item '{"order_id": {"S": "ord-001"}, "status": {"S": "pending"}}'

awslocal dynamodb scan --table-name orders-scratch
```

### SQS

```bash
# Create a queue and send a message
awslocal sqs create-queue --queue-name workshop-queue
QUEUE_URL=$(awslocal sqs get-queue-url --queue-name workshop-queue --query QueueUrl --output text)
awslocal sqs send-message --queue-url $QUEUE_URL --message-body '{"test": true}'
awslocal sqs receive-message --queue-url $QUEUE_URL
```

### Lambda (quick smoke test)

```bash
# Invoke the order_handler directly (deployed in Part B)
awslocal lambda invoke \
  --function-name order-handler \
  --payload '{"body": "{\"item\": \"book\", \"quantity\": 2}"}' \
  /tmp/response.json
cat /tmp/response.json
```

---

## Part B — Deploy with Terraform

```bash
cd 01-serverless-app/terraform

# Initialize and deploy
tflocal init
tflocal apply -auto-approve

# Grab the API Gateway endpoint
tflocal output api_endpoint
```

### Test the deployed API

```bash
API=$(tflocal output -raw api_endpoint)

# Create an order
curl -s -X POST "$API/orders" \
  -H "Content-Type: application/json" \
  -d '{"item": "LocalStack T-Shirt", "quantity": 1}' | python3 -m json.tool

# Check DynamoDB
awslocal dynamodb scan --table-name orders

# Check S3 receipts
awslocal s3 ls s3://order-receipts/
```

---

## What Got Deployed

```
API Gateway  →  Lambda: order_handler  →  DynamoDB (orders table)
                                       →  SQS (orders-queue)
                                              └→  Lambda: order_processor
                                                      →  DynamoDB (status update)
                                                      →  S3 (receipt upload)
                                              SQS DLQ ← (on processor failure)
```

---

Next: [Module 02 — E2E Testing](../02-e2e-testing/README.md)
