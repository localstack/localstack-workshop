# LocalStack Workshop

Repository with code samples for the LocalStack workshop.

Note: The project can either be cloned and installed on your local machine, or you can spin up a remote development environment (Gitpod, or Github Codespaces) to access the project directly from your browser.

* **Option 1:** Open the project in [Github Codespaces](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=630930347)
* **Option 2:** Open the project in [Gitpod](https://gitpod.io/#https://github.com/localstack/localstack-workshop)
* **Option 3:** Run the project locally (see instructions below)

## Prerequisites

* Docker
* Python/`pip`
* LocalStack Pro API key ([free trial key here](https://app.localstack.cloud))

## Installation & Getting Started

LocalStack can be started in [different ways](https://docs.localstack.cloud/getting-started/installation/).
The easiest way (the one we recommend) is through the [LocalStack CLI](https://docs.localstack.cloud/getting-started/installation/#localstack-cli).

First, install the LocalStack command-line interface (CLI):
```
pip install localstack
```
Then we can simply start the LocalStack container locally:
```
export LOCALSTACK_API_KEY=... # insert your API key here
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

Every programming language tutorial starts with printing a _Hello World_. Let us have the [equivalent](https://github.com/localstack/localstack-workshop/tree/update-after-aws-zurich/hello-world) in LocalStack.

## Deploy a Serverless App on LocalStack

It's time now to deploy a meaningful [serverless application](https://github.com/localstack/serverless-image-resizer).

## Infrastructure-as-Code Tools - Cloud Pods - LocalStack in CI

We mostly interacted with LocalStack through the CLI so far. 
However, large systems are hardly built this way.
Luckily, LocalStack supports a [wide range of integrations](https://docs.localstack.cloud/user-guide/integrations/) that will cover your favorite Infrastructure-as-Code (IaC) tool.
In the following [sample](https://github.com/giograno/serverless-api-ecs-apigateway-sample), we will first deploy a complex application with either Terraform or CloudFormation. Then, we will write a small unit test. Finally, we will close the loop by deploying and testing this app in CI with LocalStack.
