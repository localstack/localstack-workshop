# LocalStack Workshop

Repository with code samples for the LocalStack workshop.

Note: The project can either be cloned and installed on your local machine, or you can spin up a remote development environment (Gitpod, or Github Codespaces) to access the project directly from your browser.

* **Option 1:** Open project in [Github Codespaces](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=630930347)
* **Option 2:** Open project in [Gitpod](https://gitpod.io/#https://github.com/localstack/localstack-workshop)
* **Option 3:** Run project locally (see instructions below)

## Prerequisites

* Docker
* Python/`pip`
* Node/`npm` (for CDK tooling)
* LocalStack Pro API key ([free trial key here](https://app.localstack.cloud))

## Installation

First, install the LocalStack command-line interface (CLI):
```
pip install localstack
```
Then we start the LocalStack container locally:
```
export LOCALSTACK_API_KEY=... # insert your API key here
DEBUG=1 localstack start
```

Additionally, we're also installing the following packages, to make the [`awslocal`](https://github.com/localstack/awscli-local), [`tflocal`](https://github.com/localstack/terraform-local) and [`cdklocal`](https://github.com/localstack/aws-cdk-local) commands available:
```
pip install awscli-local[ver1] terraform-local
npm install -g aws-cdk-local aws-cdk
```

## Workshop Sections

### Part 1: Getting Started - Serverless Apps

Getting started by:

- Installing and starting LocalStack up;
- Play with a few CLI commmands;
- Have a look at Web App;
- Hello World in LocalStack;
- Deploy a [simple serverless application](https://github.com/localstack/serverless-image-resizer).

### Part 2: Infrastructure-as-Code Tools

Build and deploy a serverless app on LocalStack with Terraform and CloudFormation.

[serverless-api-ecs-apigateway-sample](https://github.com/giograno/serverless-api-ecs-apigateway-sample)

### Part 3: LocalStack Persistence and Cloud Pods

The resources created in LocalStack are ephemeral. However, we offer a basis [persistence mechanism](https://docs.localstack.cloud/references/persistence-mechanism/) and a more advanced [Cloud Pods](https://docs.localstack.cloud/user-guide/tools/cloud-pods/) feature for:

- collaboration: share LocalStack state in your organization;
- seed test environments with real data;
- creating reproducible sample applications.

### Part 4: LocalStack in CI Pipelines

Closing the circle by testing our serverless app in CI with LocalStack and by seeding test data with the use of [Cloud Pods](https://docs.localstack.cloud/user-guide/tools/cloud-pods/).

[aws-workshop-ci](https://github.com/giograno/aws-workshop-ci)

