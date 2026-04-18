import json
import os
import uuid
from decimal import Decimal
import boto3

dynamodb = boto3.resource("dynamodb")
sqs = boto3.client("sqs")

TABLE_NAME = os.environ["ORDERS_TABLE"]
QUEUE_URL = os.environ["ORDERS_QUEUE_URL"]

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

    if method == "OPTIONS":
        return {"statusCode": 200, "headers": CORS_HEADERS, "body": ""}

    if method == "GET":
        return list_orders()

    if method == "POST":
        return create_order(event)

    return {"statusCode": 405, "headers": CORS_HEADERS, "body": "Method Not Allowed"}


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
    order_id = str(uuid.uuid4())

    order = {
        "order_id": order_id,
        "item": body.get("item", "unknown"),
        "quantity": int(body.get("quantity", 1)),
        "status": "pending",
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
