import pytest
import boto3


endpoint_url = "http://localhost.localstack.cloud:4566"

@pytest.mark.parametrize('tableName,key', [("TablePetstoreFood", "foodName"), ("TablePetstorePets", "petName")])
def test_database(tableName, key):
    dynamodb = boto3.client("dynamodb", endpoint_url=endpoint_url, region_name='us-east-1', aws_access_key_id="test",
                            aws_secret_access_key="test")

    response = dynamodb.scan(TableName=tableName)

    items = response["Items"]

    for item in items:
        assert key in item
