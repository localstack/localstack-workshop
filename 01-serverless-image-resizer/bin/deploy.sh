#!/bin/bash

jq --version || {
    echo "Please make sure you install jq before running the deploy script"
    echo "  Mac:    brew install jq"
    echo "  Ubuntu: sudo apt install jq"
    exit 1
}

export AWS_ACCOUNT_ID=000000000000
if [ "$AWS_DEFAULT_REGION" = "" ]; then
  export AWS_DEFAULT_REGION=us-east-1
fi

awslocal s3 mb s3://localstack-thumbnails-app-images
awslocal s3 mb s3://localstack-thumbnails-app-resized

awslocal ssm put-parameter --name /localstack-thumbnail-app/buckets/images --type "String" --value "localstack-thumbnails-app-images"
awslocal ssm put-parameter --name /localstack-thumbnail-app/buckets/resized --type "String" --value "localstack-thumbnails-app-resized"

awslocal sns create-topic --name failed-resize-topic
awslocal sns subscribe \
    --topic-arn arn:aws:sns:$AWS_DEFAULT_REGION:$AWS_ACCOUNT_ID:failed-resize-topic \
    --protocol email \
    --notification-endpoint my-email@example.com

(cd lambdas/presign; rm -f lambda.zip; zip lambda.zip handler.py)
awslocal lambda create-function \
    --function-name presign \
    --runtime python3.10 \
    --timeout 10 \
    --zip-file fileb://lambdas/presign/lambda.zip \
    --handler handler.handler \
    --role arn:aws:iam::$AWS_ACCOUNT_ID:role/lambda-role

awslocal lambda wait function-active-v2 --function-name presign

awslocal lambda create-function-url-config \
    --function-name presign \
    --auth-type NONE

(cd lambdas/list; rm -f lambda.zip; zip lambda.zip handler.py)
awslocal lambda create-function \
    --function-name list \
    --runtime python3.10 \
    --timeout 10 \
    --zip-file fileb://lambdas/list/lambda.zip \
    --handler handler.handler \
    --role arn:aws:iam::$AWS_ACCOUNT_ID:role/lambda-role

awslocal lambda wait function-active-v2 --function-name list

awslocal lambda create-function-url-config \
    --function-name list \
    --auth-type NONE

os=$(uname -s)
if [ "$os" == "Darwin" ] || [ "$CODESPACES" != "true" ]; then
    (
        cd lambdas/resize
        rm -rf lambda.zip
        docker run --platform linux/x86_64 -v "$PWD":/var/task "public.ecr.aws/sam/build-python3.10" /bin/sh -c "pip install -r requirements.txt -t libs; exit"
        (cd libs && zip -r ../lambda.zip .)
        zip lambda.zip handler.py
    )
else
    (
        cd lambdas/resize
        rm -rf package lambda.zip
        mkdir -p package
        pip install -r requirements.txt -t package
        zip lambda.zip handler.py
        cd package
        zip -r ../lambda.zip *
    )
fi 

awslocal lambda create-function \
    --function-name resize \
    --runtime python3.10 \
    --timeout 10 \
    --zip-file fileb://lambdas/resize/lambda.zip \
    --handler handler.handler \
    --dead-letter-config TargetArn=arn:aws:sns:$AWS_DEFAULT_REGION:$AWS_ACCOUNT_ID:failed-resize-topic \
    --role arn:aws:iam::$AWS_ACCOUNT_ID:role/lambda-role

awslocal lambda wait function-active-v2 --function-name resize

# additionally expose API Gateway endpoints for the list/presign Lambdas, to enable path-based execution in Codespaces
presignLambdaArn=arn:aws:lambda:$AWS_DEFAULT_REGION:$AWS_ACCOUNT_ID:function:presign
apiId=$(awslocal apigatewayv2 create-api --name presign --protocol-type HTTP --tags '_custom_id_=presign' | jq -r .ApiId)
intId=$(awslocal apigatewayv2 create-integration --api-id $apiId --integration-type AWS_PROXY --payload-format-version 2.0 --integration-uri $presignLambdaArn | jq -r .IntegrationId)
awslocal apigatewayv2 create-route --api-id $apiId --authorization-type NONE --route-key "GET /{proxy+}" --target "integrations/$intId" | jq -r .RouteId
awslocal apigatewayv2 create-stage --api-id $apiId --stage-name '$default' --auto-deploy

listLambdaArn=arn:aws:lambda:$AWS_DEFAULT_REGION:$AWS_ACCOUNT_ID:function:list
apiId=$(awslocal apigatewayv2 create-api --name list --protocol-type HTTP --tags '_custom_id_=list' | jq -r .ApiId)
intId=$(awslocal apigatewayv2 create-integration --api-id $apiId --integration-type AWS_PROXY --payload-format-version 2.0 --integration-uri $listLambdaArn | jq -r .IntegrationId)
awslocal apigatewayv2 create-route --api-id $apiId --authorization-type NONE --route-key "GET /" --target "integrations/$intId" | jq -r .RouteId
awslocal apigatewayv2 create-stage --api-id $apiId --stage-name '$default' --auto-deploy


awslocal s3api put-bucket-notification-configuration \
    --bucket localstack-thumbnails-app-images \
    --notification-configuration "{\"LambdaFunctionConfigurations\": [{\"LambdaFunctionArn\": \"$(awslocal lambda get-function --function-name resize | jq -r .Configuration.FunctionArn)\", \"Events\": [\"s3:ObjectCreated:*\"]}]}"

awslocal s3 mb s3://webapp
awslocal s3 sync --delete ./website s3://webapp
awslocal s3 website s3://webapp --index-document index.html

echo "---------------------------------------------------------------------"
echo ""
echo "🎉 Success!"
echo ""

# print the function URLs
echo "Function URL for 'presign' Lambda: $(awslocal lambda list-function-url-configs --function-name presign | jq -r '.FunctionUrlConfigs[0].FunctionUrl')"
echo "Function URL for 'list' Lambda:    $(awslocal lambda list-function-url-configs --function-name list | jq -r '.FunctionUrlConfigs[0].FunctionUrl')"
echo
echo "Note: When using Codespaces, we need to use slightly different Lambda function endpoints."
echo "Replace '<your-space>' with the endpoint of your Codespace environment in the URLs below:"
echo "'presign' Lambda: https://<your-space>-4566.preview.app.github.dev/restapis/presign/dev/_user_request_"
echo "'list' Lambda:    https://<your-space>-4566.preview.app.github.dev/restapis/list/dev/_user_request_"

# Optional: use the following to test Lambda hot reloading:
#   scriptDir=$(dirname "$0")
#   awslocal lambda update-function-code --function-name list --s3-bucket hot-reload --s3-key "$scriptDir/lambdas/list"
# or, when running from the terminal directly (instead of this script):
#   awslocal lambda update-function-code --function-name list --s3-bucket hot-reload --s3-key "$(pwd)/lambdas/list"
