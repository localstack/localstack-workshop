# Module 02 — End-to-End Testing

Write integration tests that run against the locally deployed stack — no mocking.

> **Prerequisite:** Module 01 deployed (`tflocal apply` completed).

---

## Run the Tests

```bash
cd 02-e2e-testing
pip install -r requirements.txt
pytest tests/ -v
```

---

## Test Structure

```
02-e2e-testing/
├── tests/
│   ├── conftest.py          # shared fixtures (boto3 clients, API endpoint)
│   ├── test_order_flow.py   # happy path: create order → processed → receipt in S3
│   └── test_api.py          # API Gateway input validation
└── requirements.txt
```

---

## Key Ideas

- Tests talk to `http://localhost:4566` — the same endpoint your app uses
- No mocking: real DynamoDB, real SQS, real S3
- Tests wait for async processing (SQS → Lambda) with a short poll loop
- If a test fails, the state is preserved — inspect with `awslocal` commands

```bash
# Inspect leftover state after a failed test
awslocal dynamodb scan --table-name orders
awslocal sqs get-queue-attributes \
  --queue-url http://localhost:4566/000000000000/orders-dlq \
  --attribute-names ApproximateNumberOfMessages
```

---

Next: [Module 03 — IAM Enforcement](../03-iam-enforcement/README.md)
