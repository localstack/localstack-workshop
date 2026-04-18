import json
import os
import time
import uuid
from datetime import datetime, timezone
import boto3

dynamodb = boto3.resource("dynamodb")
s3 = boto3.client("s3")
sfn = boto3.client("stepfunctions")

TABLE_NAME = os.environ["ORDERS_TABLE"]
RECEIPTS_BUCKET = os.environ["RECEIPTS_BUCKET"]
STATE_MACHINE_ARN = os.environ["STATE_MACHINE_ARN"]

TERMINAL_STATUSES = {"fulfilled", "failed"}


def now():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def set_status(order_id, status):
    ts_key = {
        "validating":          "validating_at",
        "payment_processing":  "payment_at",
        "fulfilled":           "fulfilled_at",
        "failed":              "failed_at",
    }.get(status)

    expression = "SET #s = :s"
    names  = {"#s": "status"}
    values = {":s": status}

    if ts_key:
        expression += ", #ts = :ts"
        names["#ts"]  = ts_key
        values[":ts"] = now()

    dynamodb.Table(TABLE_NAME).update_item(
        Key={"order_id": order_id},
        UpdateExpression=expression,
        ExpressionAttributeNames=names,
        ExpressionAttributeValues=values,
    )


def handler(event, context):
    # Triggered by SQS: start a state machine execution per order
    if "Records" in event:
        for record in event["Records"]:
            order = json.loads(record["body"])
            sfn.start_execution(
                stateMachineArn=STATE_MACHINE_ARN,
                name=f"order-{order['order_id']}-{uuid.uuid4().hex[:8]}",
                input=json.dumps({"order": order}),
            )
        return

    # Invoked by Step Functions
    step  = event["step"]
    order = event["order"]

    if step == "validate":        return validate(order)
    if step == "process_payment": return process_payment(order)
    if step == "fulfill":         return fulfill(order)
    if step == "handle_failure":  return handle_failure(order)

    raise ValueError(f"Unknown step: {step}")


def validate(order):
    time.sleep(2)
    set_status(order["order_id"], "validating")
    return order


def process_payment(order):
    time.sleep(3)
    set_status(order["order_id"], "payment_processing")
    return order


def fulfill(order):
    time.sleep(2)
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
