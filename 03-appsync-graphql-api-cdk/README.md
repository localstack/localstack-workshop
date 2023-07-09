# AppSync GraphQL APIs for DynamoDB and RDS Aurora PostgreSQL

| Key          | Value                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| ------------ |---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Environment  | <img src="https://img.shields.io/badge/LocalStack-deploys-4D29B4.svg?logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAKgAAACoABZrFArwAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAALbSURBVHic7ZpNaxNRFIafczNTGIq0G2M7pXWRlRv3Lusf8AMFEQT3guDWhX9BcC/uFAr1B4igLgSF4EYDtsuQ3M5GYrTaj3Tmui2SpMnM3PlK3m1uzjnPw8xw50MoaNrttl+r1e4CNRv1jTG/+v3+c8dG8TSilHoAPLZVX0RYWlraUbYaJI2IuLZ7KKUWCisgq8wF5D1A3rF+EQyCYPHo6Ghh3BrP8wb1en3f9izDYlVAp9O5EkXRB8dxxl7QBoNBpLW+7fv+a5vzDIvVU0BELhpjJrmaK2NMw+YsIxunUaTZbLrdbveZ1vpmGvWyTOJToNlsuqurq1vAdWPMeSDzwzhJEh0Bp+FTmifzxBZQBXiIKaAq8BBDQJXgYUoBVYOHKQRUER4mFFBVeJhAQJXh4QwBVYeHMQJmAR5GCJgVeBgiYJbg4T8BswYPp+4GW63WwvLy8hZwLcd5TudvBj3+OFBIeA4PD596nvc1iiIrD21qtdr+ysrKR8cY42itCwUP0Gg0+sC27T5qb2/vMunB/0ipTmZxfN//orW+BCwmrGV6vd63BP9P2j9WxGbxbrd7B3g14fLfwFsROUlzBmNM33XdR6Meuxfp5eg54IYxJvXCx8fHL4F3w36blTdDI4/0WREwMnMBeQ+Qd+YC8h4g78wF5D1A3rEqwBiT6q4ubpRSI+ewuhP0PO/NwcHBExHJZZ8PICI/e73ep7z6zzNPwWP1djhuOp3OfRG5kLROFEXv19fXP49bU6TbYQDa7XZDRF6kUUtEtoFb49YUbh/gOM7YbwqnyG4URQ/PWlQ4ASllNwzDzY2NDX3WwioKmBgeqidgKnioloCp4aE6AmLBQzUExIaH8gtIBA/lFrCTFB7KK2AnDMOrSeGhnAJSg4fyCUgVHsolIHV4KI8AK/BQDgHW4KH4AqzCQwEfiIRheKKUAvjuuu7m2tpakPdMmcYYI1rre0EQ1LPo9w82qyNziMdZ3AAAAABJRU5ErkJggg=="> |
| Services     | DynamoDB, RDS, AppSync                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| Integrations | Cloud Development Kit (CDK)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| Categories   | CDK; Databases                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| Level        | Intermediate                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| GitHub       | [Repository link](https://github.com/localstack/appsync-graphql-api-sample)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |

## Introduction

The AppSync GraphQL APIs for DynamoDB and RDS Aurora PostgreSQL application sample demonstrates how you can proxy data from different resources such as DynamoDB tables & RDS databases using AppSync GraphQL APIs deployed on LocalStack. The application sample leverages a secure WebSocket connection that remains constantly connected to the AppSync GraphQL API and receives real-time data from the AppSync Data Sources (DynamoDB, RDS). Users can deploy this application setup via the Cloud Development Kit (CDK) on AWS & LocalStack with no changes. To test this application sample, we will demonstrate how you use LocalStack to deploy the infrastructure on your developer machine and your CI environment and invoke the AppSync API for DynamoDB and RDS integration.

## Architecture diagram

The following diagram shows the architecture that this sample application builds and deploys:

![Architecture diagram for AppSync GraphQL APIs for DynamoDB and RDS Aurora PostgreSQL](./images/appsync-datasource-architecture.png)

We are using the following AWS services and third-party integrations to build our infrastructure:

- [AppSync](https://docs.localstack.cloud/user-guide/aws/appsync/) to integrate with the Data Sources (DynamoDB, RDS) and to provide a GraphQL API which can be connected to a WebSocket connection.
- [DynamoDB](https://docs.localstack.cloud/user-guide/aws/dynamodb/) & [RDS](https://docs.localstack.cloud/user-guide/aws/rds/) to store the data for the GraphQL API and initiate a CRUDL (Create-Read-Update-Delete-List) logic in a GraphQL API.
- AWS CDK as our Infrastructure as Code framework to deploy the infrastructure on AWS & LocalStack with no changes, along with the [`cdklocal`](https://github.com/localstack/aws-cdk-local) CLI.

## Prerequisites

- LocalStack Pro with the [`localstack` CLI](https://docs.localstack.cloud/getting-started/installation/#localstack-cli).
- [AWS CLI](https://docs.localstack.cloud/user-guide/integrations/aws-cli/) with the [`awslocal` wrapper](https://docs.localstack.cloud/user-guide/integrations/aws-cli/#localstack-aws-cli-awslocal).
- [Python](https://www.python.org/downloads/)
- [`cURL`](https://curl.se/)
- [`wscat`](https://github.com/websockets/wscat)

Start LocalStack Pro with the `LOCALSTACK_API_KEY` pre-configured:

```sh
export LOCALSTACK_API_KEY=<your-api-key>
localstack start
```

> If you prefer running LocalStack in detached mode, you can add the `-d` flag to the `localstack start` command, and use Docker Desktop to view the logs.

## Instructions

You can build and deploy the sample application on LocalStack by running our `Makefile` commands. Run `make install` to install the dependencies and `make run` to create the infrastructure on LocalStack. Run `make stop` to delete the infrastructure by stopping LocalStack.

Alternatively, here are instructions to deploy it manually step-by-step.

### Install the dependencies

Run the following commands to create a Python virtual environment and install the dependencies:

```sh
virtualenv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### Deploy the infrastructure

To deploy the infrastructure, we are using the AWS CDK with the `cdklocal` CLI. The `cdklocal` CLI ensures that requests to AWS are redirected to a running LocalStack instance.

Before deploying the infrastructure, we need to install the dependencies. Run the following commands to install the dependencies:

To deploy the infrastructure, run the following command and confirm the deployment with "y":

```sh
(
  . .venv/bin/activate
  cd cdk
  cdklocal bootstrap
  cdklocal deploy
)
```

After a few seconds, the infrastructure should be deployed successfully. Fetch the API ID and API Key by running the following commands:

```sh
export APPSYNC_URL=http://localhost:4566/graphql
api_id=$(awslocal appsync list-graphql-apis | jq -r '(.graphqlApis[] | select(.name=="test-api")).apiId')
api_key=$(awslocal appsync create-api-key --api-id $api_id | jq -r .apiKey.id)
echo $api_key
echo $api_id
```

### Setup a WebSocket connection

Next, we need to create a WebSocket connection to the AppSync GraphQL API. Run the following command to create a WebSocket connection:

```sh
python websocket_client.py $api_id
```

The above script will make use of the `wscat` utility for testing the AppSync GraphQL API. The script will create a WebSocket connection using the SDK for Python (Boto3) and start a subscription client. To disconnect from your API, enter **CTRL-C**.

### Test the GraphQL API

To test the GraphQL API, we will use `cURL` to invoke the integrations with DynamoDB and RDS. Let us send a mutation request to the AppSync API to add a new post to the DynamoDB data source. The mutation specifies the `addPostDDB` field and provides the `id` parameter with a value of `id123`. The response from the API will include the `id` of the newly created post.

```sh
curl -H "Content-Type: application/json" -H "x-api-key: $api_key" -d '{"query":"mutation {addPostDDB(id: \"id123\"){id}}"}' $APPSYNC_URL/$api_id
```

Let us now send a query request to the AppSync API to retrieve all posts from the DynamoDB data source:

```sh
curl -H "Content-Type: application/json" -H "x-api-key: $api_key" -d '{"query":"query {getPostsDDB{id}}"}' $APPSYNC_URL/$api_id
```

We can now perform a scan operation on the DynamoDB table which will include an entry with `id123` as the `id`:

```sh
awslocal dynamodb scan --table-name table1
{
    "Items": [
        {
            "id": {
                "S": "id123"
            }
        }
    ],
    "Count": 1,
    "ScannedCount": 1,
    "ConsumedCapacity": null
}
```

You should also see a message printed from the WebSocket client subscribed to notifications from the API:

```sh
...
Starting a WebSocket client to subscribe to GraphQL mutation operations.
Connecting to WebSocket URL ws://localhost:4510/graphql/...
...
Received notification message from WebSocket: {"addedPost": {"id": "id123"}}
```

We can perform a similar operation on the RDS database:

```sh
curl -H "Content-Type: application/json" -H "x-api-key: $api_key" -d '{"query":"mutation {addPostRDS(id: \"id123\"){id}}"}' $APPSYNC_URL/$api_id
curl -H "Content-Type: application/json" -H "x-api-key: $api_key" -d '{"query":"query {getPostsRDS{id}}"}' $APPSYNC_URL/$api_id
```

You can check out your local AWS resources on the [LocalStack Web Application](https://app.localstack.cloud/) on [RDS](https://app.localstack.cloud/resources/rds/clusters), [DynamoDB](https://app.localstack.cloud/resources/dynamodb), and [AppSync](https://app.localstack.cloud/resources/appsync) Resource Browsers.

### GitHub Action

This application sample hosts an example GitHub Action workflow that starts up LocalStack, builds the Lambda functions, and deploys the infrastructure on the runner. You can find the workflow in the `.github/workflows/main.yml` file. To run the workflow, you can fork this repository and push a commit to the `main` branch.

Users can adapt this example workflow to run in their own CI environment. LocalStack supports various CI environments, including GitHub Actions, CircleCI, Jenkins, Travis CI, and more. You can find more information about the CI integration in the [LocalStack documentation](https://docs.localstack.cloud/user-guide/ci/).

## Contributing

We appreciate your interest in contributing to our project and are always looking for new ways to improve the developer experience. We welcome feedback, bug reports, and even feature ideas from the community.
Please refer to the [contributing file](CONTRIBUTING.md) for more details on how to get started. 
