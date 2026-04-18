"""ECS task: fulfill an order — update DynamoDB status and write S3 receipt."""
import json
import os
from datetime import datetime, timezone

import boto3

ORDER_ID        = os.environ["ORDER_ID"]
TABLE_NAME      = os.environ["ORDERS_TABLE"]
RECEIPTS_BUCKET = os.environ["RECEIPTS_BUCKET"]

endpoint = os.environ.get("AWS_ENDPOINT_URL", "")
print(f"Connecting to endpoint: {endpoint or '(default AWS)'}", flush=True)

dynamodb = boto3.resource("dynamodb")
s3       = boto3.client("s3")


def now():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


table = dynamodb.Table(TABLE_NAME)

resp  = table.get_item(Key={"order_id": ORDER_ID})
order = resp["Item"]

table.update_item(
    Key={"order_id": ORDER_ID},
    UpdateExpression="SET #s = :s, fulfilled_at = :ts",
    ExpressionAttributeNames={"#s": "status"},
    ExpressionAttributeValues={":s": "fulfilled", ":ts": now()},
)

receipt = {
    "order_id": ORDER_ID,
    "item":     order["item"],
    "quantity": int(order["quantity"]),
    "status":   "fulfilled",
    "fulfilled_at": now(),
}
s3.put_object(
    Bucket=RECEIPTS_BUCKET,
    Key=f"receipts/{ORDER_ID}.json",
    Body=json.dumps(receipt),
    ContentType="application/json",
)

print(f"Order {ORDER_ID} fulfilled: {order['item']} x{order['quantity']}")
