import json
import os
import boto3

dynamodb = boto3.resource("dynamodb")
s3 = boto3.client("s3")
sfn = boto3.client("stepfunctions")

TABLE_NAME = os.environ["ORDERS_TABLE"]
RECEIPTS_BUCKET = os.environ["RECEIPTS_BUCKET"]
STATE_MACHINE_ARN = os.environ["STATE_MACHINE_ARN"]


def handler(event, context):
    # Triggered by SQS: kick off the state machine for each order
    if "Records" in event:
        for record in event["Records"]:
            order = json.loads(record["body"])
            sfn.start_execution(
                stateMachineArn=STATE_MACHINE_ARN,
                name=f"order-{order['order_id']}",
                input=json.dumps({"order": order}),
            )
        return

    # Invoked by Step Functions with a step parameter
    step = event["step"]
    order = event["order"]

    if step == "validate":
        return validate(order)
    if step == "process_payment":
        return process_payment(order)
    if step == "fulfill":
        return fulfill(order)
    if step == "handle_failure":
        return handle_failure(order)

    raise ValueError(f"Unknown step: {step}")


def set_status(order_id, status):
    dynamodb.Table(TABLE_NAME).update_item(
        Key={"order_id": order_id},
        UpdateExpression="SET #s = :s",
        ExpressionAttributeNames={"#s": "status"},
        ExpressionAttributeValues={":s": status},
    )


def validate(order):
    set_status(order["order_id"], "validating")
    return order


def process_payment(order):
    set_status(order["order_id"], "payment_processing")
    return order


def fulfill(order):
    set_status(order["order_id"], "fulfilled")
    receipt = {k: order[k] for k in ("order_id", "item", "quantity")}
    receipt["status"] = "fulfilled"
    s3.put_object(
        Bucket=RECEIPTS_BUCKET,
        Key=f"receipts/{order['order_id']}.json",
        Body=json.dumps(receipt),
        ContentType="application/json",
    )
    return order


def handle_failure(order):
    set_status(order["order_id"], "failed")
    return order
