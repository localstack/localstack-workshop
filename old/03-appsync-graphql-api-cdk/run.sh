#!/bin/bash

if [ "$AWS_DEFAULT_REGION" = "" ]; then
  export AWS_DEFAULT_REGION=us-east-1
fi

APPSYNC_URL=http://localhost:4566/graphql

api_id=$(awslocal appsync list-graphql-apis | jq -r '(.graphqlApis[] | select(.name=="test-api")).apiId') && \
echo "DEBUG: api_id is: $api_id" && \
api_key=$(awslocal appsync create-api-key --api-id $api_id | jq -r .apiKey.id) && \
echo "DEBUG: api_key is: $api_key" && \
echo "Now trying to invoke the AppSync API for DynamoDB integration under $APPSYNC_URL/$api_id." && \
curl -H "Content-Type: application/json" -H "x-api-key: $api_key" -d '{"query":"mutation {addPostDDB(id: \"id123\"){id}}"}' $APPSYNC_URL/$api_id && \
curl -H "Content-Type: application/json" -H "x-api-key: $api_key" -d '{"query":"query {getPostsDDB{id}}"}' $APPSYNC_URL/$api_id && \
echo "Scanning items from DynamoDB table - should include entry with 'id123':" && \
result_ddb_scan=$(awslocal dynamodb scan --table-name table1) && \
echo $result_ddb_scan | jq -r . && \
echo "Now trying to invoke the AppSync API for RDS integration." && \
curl -H "Content-Type: application/json" -H "x-api-key: $api_key" -d '{"query":"mutation {addPostRDS(id: \"id123\"){id}}"}' $APPSYNC_URL/$api_id && \
result_rds=$(curl -H "Content-Type: application/json" -H "x-api-key: $api_key" -d '{"query":"query {getPostsRDS{id}}"}' $APPSYNC_URL/$api_id) && \
echo $result_rds
expected_id_rds=$(echo $result_rds | jq -r .data.getPostsRDS[0].id)
expected_id_ddb=$(echo $result_ddb_scan | jq -r .Items[0].id.S)
if [[ $expected_id_rds != "id123" ]] || [[ $expected_id_ddb != "id123" ]]; then
    echo unexpected id query results: $expected_id_rds, $expected_id_ddb
    exit 1
fi
