# This is a simple Python script to illustrate the use of boto3, the AWS SDK
#  for Python. We use a boto3 client below to list all S3 buckets and objects.
import os

import boto3

LOCALSTACK_ENDPOINT = "http://localhost:4566"
AWS_REGION = os.environ.get("AWS_DEFAULT_REGION", "us-east-1")


def main():
    client = boto3.client(
        "s3",
        endpoint_url=LOCALSTACK_ENDPOINT,
        aws_access_key_id="test",
        aws_secret_access_key="test",
        region_name=AWS_REGION
    )

    buckets = client.list_buckets()["Buckets"]
    for bucket in buckets:
        print(f"Found bucket: {bucket['Name']}")
        objects = client.list_objects(Bucket=bucket["Name"]).get("Contents", [])
        for obj in objects:
            print(f"Found object: s3://{bucket['Name']}/{obj['Key']}")


if __name__ == "__main__":
    main()
