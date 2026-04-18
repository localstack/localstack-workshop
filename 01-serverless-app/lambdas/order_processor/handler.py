import json
import boto3

dynamodb = boto3.resource("dynamodb")
s3 = boto3.client("s3")

TABLE_NAME = os.environ["ORDERS_TABLE"]
RECEIPTS_BUCKET = os.environ["RECEIPTS_BUCKET"]


def handler(event, context):
    for record in event["Records"]:
        order = json.loads(record["body"])
        order_id = order["order_id"]

        # Update order status in DynamoDB
        table = dynamodb.Table(TABLE_NAME)
        table.update_item(
            Key={"order_id": order_id},
            UpdateExpression="SET #s = :s",
            ExpressionAttributeNames={"#s": "status"},
            ExpressionAttributeValues={":s": "processed"},
        )

        # Store receipt in S3
        receipt = {
            "order_id": order_id,
            "item": order.get("item"),
            "quantity": order.get("quantity"),
            "status": "processed",
        }
        s3.put_object(
            Bucket=RECEIPTS_BUCKET,
            Key=f"receipts/{order_id}.json",
            Body=json.dumps(receipt),
            ContentType="application/json",
        )
