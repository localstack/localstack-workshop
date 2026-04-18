import boto3
import pytest

ENDPOINT = "http://localhost:4566"
REGION = "us-east-1"
AWS_KWARGS = dict(
    endpoint_url=ENDPOINT,
    region_name=REGION,
    aws_access_key_id="test",
    aws_secret_access_key="test",
)


@pytest.fixture
def dynamodb():
    return boto3.resource("dynamodb", **AWS_KWARGS)


@pytest.fixture
def s3():
    return boto3.client("s3", **AWS_KWARGS)


@pytest.fixture
def sqs():
    return boto3.client("sqs", **AWS_KWARGS)


@pytest.fixture
def api_endpoint():
    import subprocess, json
    result = subprocess.check_output(
        ["tflocal", "output", "-json", "api_endpoint"],
        cwd="../01-serverless-app/terraform",
    )
    return json.loads(result)
