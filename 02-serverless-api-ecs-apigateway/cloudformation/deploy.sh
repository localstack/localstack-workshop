#!/bin/bash

# create the bucket that hosts the webapp
awslocal s3 mb s3://sample-app
awslocal s3 sync ../client-application-react/build s3://sample-app

# generate the URL to host the web application

export API_ID=$(awslocal apigatewayv2 get-apis | jq -r '.Items[] | select(.Name=="ecsapi-demo") | .ApiId')
export POOL_ID=$(awslocal cognito-idp list-user-pools --max-results 1 | jq -r '.UserPools[0].Id')
export CLIENT_ID=$(awslocal cognito-idp list-user-pool-clients --user-pool-id $POOL_ID | jq -r '.UserPoolClients[0].ClientId')
export URL="http://sample-app.s3.localhost.localstack.cloud:4566/index.html?stackregion=us-east-1&stackhttpapi=$API_ID&stackuserpool=$POOL_ID&stackuserpoolclient=$CLIENT_ID"
echo $URL


