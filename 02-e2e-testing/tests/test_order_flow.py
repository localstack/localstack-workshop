import json
import time
import requests


def test_create_order_returns_order_id(api_endpoint):
    resp = requests.post(f"{api_endpoint}/orders", json={"item": "book", "quantity": 2})
    assert resp.status_code == 201
    data = resp.json()
    assert "order_id" in data
    assert data["status"] == "pending"


def test_order_persisted_in_dynamodb(api_endpoint, dynamodb):
    resp = requests.post(f"{api_endpoint}/orders", json={"item": "mug", "quantity": 1})
    order_id = resp.json()["order_id"]

    table = dynamodb.Table("orders")
    item = table.get_item(Key={"order_id": order_id})["Item"]
    assert item["item"] == "mug"
    assert item["status"] == "pending"


def test_order_processed_and_receipt_in_s3(api_endpoint, dynamodb, s3):
    resp = requests.post(f"{api_endpoint}/orders", json={"item": "t-shirt", "quantity": 3})
    order_id = resp.json()["order_id"]

    # Wait for async SQS → Lambda processing (up to 10s)
    table = dynamodb.Table("orders")
    for _ in range(20):
        item = table.get_item(Key={"order_id": order_id})["Item"]
        if item["status"] == "processed":
            break
        time.sleep(0.5)
    else:
        raise AssertionError(f"Order {order_id} never reached 'processed' status")

    # Verify receipt uploaded to S3
    obj = s3.get_object(Bucket="order-receipts", Key=f"receipts/{order_id}.json")
    receipt = json.loads(obj["Body"].read())
    assert receipt["order_id"] == order_id
    assert receipt["status"] == "processed"
