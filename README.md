![Build Status](https://github.com/localstack/localstack-workshop/actions/workflows/build-test.yml/badge.svg)

# LocalStack Workshop

Repository with code samples for the LocalStack workshop.

Note: The project can either be cloned and installed on your local machine, or you can spin up a remote development environment (Gitpod, or Github Codespaces) to access the project directly from your browser.

* **Option 1:** Open the project in [Github Codespaces](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=630930347)
* **Option 2:** Open the project in [Gitpod](https://gitpod.io/#https://github.com/localstack/localstack-workshop)
* **Option 3:** Run the project locally (see instructions below)

## Prerequisites

* Docker
* Python/`pip`
* LocalStack Pro auth token ([free trial key here](https://app.localstack.cloud))

## Installation & Getting Started

LocalStack can be started in [different ways](https://docs.localstack.cloud/getting-started/installation/).
The easiest way (the one we recommend) is through the [LocalStack CLI](https://docs.localstack.cloud/getting-started/installation/#localstack-cli).

First, install the LocalStack command-line interface (CLI):
```
pip install localstack
```
Then we can simply start the LocalStack container locally:
```
export LOCALSTACK_AUTH_TOKEN=... # insert your auth token here
DEBUG=1 localstack start
```

Once LocalStack is running in the Docker container, we can issue CLI commands to create and interact with AWS resources. Let's say, for instance, that we want to create a S3 bucket. 
If you have the [AWS Command Line Interface](https://aws.amazon.com/cli/) installed on your machine, you can simply type:
```
aws --endpoint=http://localhost.localstack.cloud:4566 s3 mb s3://demo-bucket
```

To make things simpler, you might want to install [`awslocal`](https://github.com/localstack/awscli-local), i.e., our wrapper around the AWS CLI. This way, you don't need to set up the endpoint for every CLI command. The previous command would just be:
```
awslocal s3 mb s3://demo-bucket
```

You can create and browse resources in LocalStack also from the research browser.
Simply, go to our [Web App](https://app.localstack.cloud/), log in, and click on _Resources_ in the top navigation bar. You will gain access to our research browser, where each service has a console to manage its resources.

### Hello World

Every programming language tutorial starts with printing a _Hello World_. Let us have the [equivalent](https://github.com/localstack/localstack-workshop/tree/main/00-hello-world) in LocalStack.

## Sample 1: Deploy a Serverless App on LocalStack

As the next step, we'll deploy a [serverless application](./01-serverless-image-resizer) using Lambda, S3, SNS, and other AWS services.
This is an app to resize images uploaded to an S3 bucket, using Lambda functions and event-driven processing.
A simple web fronted using HTML and JavaScript provides a way for users to upload images that are resized and listed.

## Sample 3: Infrastructure-as-Code Tools and Containerized Applications

We mostly interacted with LocalStack through the CLI so far. However, large systems are hardly built this way.
Luckily, LocalStack supports a [wide range of integrations](https://docs.localstack.cloud/user-guide/integrations/) that will cover your favorite Infrastructure-as-Code (IaC) tool.
In the following [sample](./02-serverless-api-ecs-apigateway), we will deploy a containerized application (using ECS, Cognito, etc) with either Terraform or CloudFormation.

## Sample 4: AppSync GraphQL APIs for DynamoDB and RDS Aurora PostgreSQL

In this sample, we'll take a closer look at AppSync, a managed services for deploying GraphQL APIs to access data sources like RDS databases or DynamoDB tables.
The [AppSync GraphQL sample](./03-appsync-graphql-api-cdk) is a simple application that maintaines entries in a database table, and makes them accessible via a GraphQL HTTP endpoint.
Clients can also subscribe to a WebSocket endpoint to receive real-time updates about new DB entries. The stack is defined via CDK, and deployed fully locally against LocalStack.

## Sample 5: Cloud Pods

Details following soon...
