import json
import time
import requests


def test_create_order_returns_order_id(api_endpoint):
    resp = requests.post(f"{api_endpoint}/orders", json={"item": "LocalStack T-Shirt", "quantity": 2})
    assert resp.status_code == 201
    data = resp.json()
    assert "order_id" in data
    assert data["status"] == "pending"


def test_order_persisted_in_dynamodb(api_endpoint, dynamodb):
    resp = requests.post(f"{api_endpoint}/orders", json={"item": "LocalStack Mug", "quantity": 1})
    order_id = resp.json()["order_id"]

    table = dynamodb.Table("orders")
    item = table.get_item(Key={"order_id": order_id})["Item"]
    assert item["item"] == "LocalStack Mug"
    assert item["status"] == "pending"


def test_order_fulfilled_and_receipt_in_s3(api_endpoint, dynamodb, s3):
    resp = requests.post(f"{api_endpoint}/orders", json={"item": "LocalStack Hoodie", "quantity": 1})
    assert resp.status_code == 201
    order_id = resp.json()["order_id"]

    # Wait for full pipeline: SQS → Lambda → Step Functions → ECS (up to 60s)
    table = dynamodb.Table("orders")
    for _ in range(120):
        item = table.get_item(Key={"order_id": order_id})["Item"]
        if item["status"] in ("fulfilled", "failed"):
            break
        time.sleep(0.5)
    else:
        raise AssertionError(f"Order {order_id} never reached terminal status (last: {item['status']})")

    assert item["status"] == "fulfilled", f"Expected fulfilled, got {item['status']}"

    # Verify receipt uploaded to S3 by the ECS fulfillment task
    obj = s3.get_object(Bucket="order-receipts", Key=f"receipts/{order_id}.json")
    receipt = json.loads(obj["Body"].read())
    assert receipt["order_id"] == order_id
    assert receipt["status"] == "fulfilled"


def test_products_listed(api_endpoint):
    resp = requests.get(f"{api_endpoint}/products")
    assert resp.status_code == 200
    products = resp.json()
    assert len(products) > 0
    names = [p["name"] for p in products]
    assert any("LocalStack" in n for n in names)
