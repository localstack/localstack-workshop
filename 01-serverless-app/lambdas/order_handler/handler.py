import json
import os
import uuid
import boto3

dynamodb = boto3.resource("dynamodb", endpoint_url=os.environ.get("AWS_ENDPOINT_URL"))
sqs = boto3.client("sqs", endpoint_url=os.environ.get("AWS_ENDPOINT_URL"))

TABLE_NAME = os.environ["ORDERS_TABLE"]
QUEUE_URL = os.environ["ORDERS_QUEUE_URL"]


def handler(event, context):
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
        "body": json.dumps({"order_id": order_id, "status": "pending"}),
    }
