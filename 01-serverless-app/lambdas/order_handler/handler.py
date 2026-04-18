import json
import os
import uuid
from datetime import datetime, timezone
from decimal import Decimal
import boto3

dynamodb = boto3.resource("dynamodb")
sqs = boto3.client("sqs")

TABLE_NAME     = os.environ["ORDERS_TABLE"]
PRODUCTS_TABLE = os.environ["PRODUCTS_TABLE"]
QUEUE_URL      = os.environ["ORDERS_QUEUE_URL"]
DLQ_URL        = os.environ.get("ORDERS_DLQ_URL", "")

class DecimalEncoder(json.JSONEncoder):
    def default(self, o):
        return int(o) if isinstance(o, Decimal) else super().default(o)


CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
}


def handler(event, context):
    method = event.get("httpMethod", "")
    path   = event.get("path", "")

    if method == "OPTIONS":
        return {"statusCode": 200, "headers": CORS_HEADERS, "body": ""}

    if method == "POST" and path.endswith("/replay"):
        return replay_dlq()

    if method == "GET" and "/products" in path:
        return list_products()

    if method == "GET":
        return list_orders()

    if method == "POST":
        return create_order(event)

    return {"statusCode": 405, "headers": CORS_HEADERS, "body": "Method Not Allowed"}


def replay_dlq():
    resp = sqs.receive_message(QueueUrl=DLQ_URL, MaxNumberOfMessages=10)
    messages = resp.get("Messages", [])
    for msg in messages:
        sqs.send_message(QueueUrl=QUEUE_URL, MessageBody=msg["Body"])
        sqs.delete_message(QueueUrl=DLQ_URL, ReceiptHandle=msg["ReceiptHandle"])
    return {
        "statusCode": 200,
        "headers": {**CORS_HEADERS, "Content-Type": "application/json"},
        "body": json.dumps({"replayed": len(messages)}),
    }


def list_products():
    table = dynamodb.Table(PRODUCTS_TABLE)
    items = sorted(table.scan().get("Items", []), key=lambda x: x.get("name", ""))
    return {
        "statusCode": 200,
        "headers": {**CORS_HEADERS, "Content-Type": "application/json"},
        "body": json.dumps(items, cls=DecimalEncoder),
    }


def list_orders():
    table = dynamodb.Table(TABLE_NAME)
    result = table.scan()
    items = sorted(result.get("Items", []), key=lambda x: x.get("order_id", ""))
    return {
        "statusCode": 200,
        "headers": {**CORS_HEADERS, "Content-Type": "application/json"},
        "body": json.dumps(items, cls=DecimalEncoder),
    }


def create_order(event):
    body = json.loads(event.get("body") or "{}")
    order_id = uuid.uuid4().hex[:12]

    order = {
        "order_id": order_id,
        "item": body.get("item", "unknown"),
        "quantity": int(body.get("quantity", 1)),
        "status": "pending",
        "created_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }

    table = dynamodb.Table(TABLE_NAME)
    table.put_item(Item=order)

    sqs.send_message(
        QueueUrl=QUEUE_URL,
        MessageBody=json.dumps({"order_id": order_id, **order}),
    )

    return {
        "statusCode": 201,
        "headers": {**CORS_HEADERS, "Content-Type": "application/json"},
        "body": json.dumps({"order_id": order_id, "status": "pending"}),
    }
