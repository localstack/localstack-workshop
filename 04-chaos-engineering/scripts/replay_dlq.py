"""Read messages from DLQ (stdin as JSON from awslocal) and resend to the main queue."""
import json
import sys
import boto3

ENDPOINT = "http://localhost:4566"
MAIN_QUEUE = "http://localhost:4566/000000000000/orders-queue"
DLQ = "http://localhost:4566/000000000000/orders-dlq"

sqs = boto3.client(
    "sqs",
    endpoint_url=ENDPOINT,
    region_name="us-east-1",
    aws_access_key_id="test",
    aws_secret_access_key="test",
)

raw = sys.stdin.read().strip()
if not raw:
    print("DLQ is empty.")
    sys.exit(0)

data = json.loads(raw)
messages = data.get("Messages", [])

if not messages:
    print("DLQ is empty.")
    sys.exit(0)

for msg in messages:
    sqs.send_message(QueueUrl=MAIN_QUEUE, MessageBody=msg["Body"])
    sqs.delete_message(QueueUrl=DLQ, ReceiptHandle=msg["ReceiptHandle"])
    print(f"Replayed message {msg['MessageId']}")

print(f"Replayed {len(messages)} message(s) from DLQ to main queue.")
