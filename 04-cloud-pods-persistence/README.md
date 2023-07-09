# Persistence and State Sharing via Cloud Pods

## Prerequisites

* LocalStack Team plan (configured with API key)
* `localstack` CLI

To install the latest dev release of the CLI, we can use this command:
```
$ pip install --upgrade --pre localstack localstack-ext
```

Using cloud pods requires creating an account on https://app.localstack.cloud, and then using the account credentials to log in to the CLI:
```
$ localstack login
...
```

## Creating Cloud Pods locally

First, let's create some resources - S3 buckets, SQS queues, ...:
```
awslocal s3 mb s3://test-bucket
awslocal sqs create-queue –-queue-name q1
awslocal cognito-idp create-user-pool --pool-name p1
```

We can then store the state to a local cloud pod file:
```
localstack pod save file://my-cloud-pod.zip
```

Now - let's restart the LocalStack instance, and load the state back in:
```
localstack pod load file://my-cloud-pod.zip
```

## Creating Cloud Pods remotely - team collaboration

First, make sure your `localstack` CLI is logged in to the shared demo account provided in the workshop.

Then, let's create some state in the LocalStack instance, same as in the previous section.

Choose a sufficiently random name, then save the cloud pod remotely (note that no `file://` protocol is specified here):
```
localstack pod save my-pod-512398
```

Browse the existing cloud pods in the [Web application](https://app.localstack.cloud/pods), then inject one!
This way you can see the resources and files from your team colleagues (or other workshop attendees)!
