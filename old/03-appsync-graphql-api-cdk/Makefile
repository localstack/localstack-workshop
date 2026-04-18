export AWS_ACCESS_KEY_ID ?= test
export AWS_SECRET_ACCESS_KEY ?= test
export AWS_DEFAULT_REGION ?= us-east-1
SHELL := /bin/bash

usage:       ## Show this help
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

install:     ## Install dependencies
	@test -e node_modules || yarn install
	@which serverless || yarn add serverless
	@which localstack || pip install localstack
	@which awslocal || pip install awscli-local
	@test -e .venv || (python3 -m venv .venv; source .venv/bin/activate; pip install -r requirements.txt)

deploy:      ## Deploy the app locally
	echo "Deploying application to local environment"
	. .venv/bin/activate && cd cdk && cdklocal bootstrap && cdklocal deploy --require-approval=never
	echo "Application successfully deployed."

run:         ## Deploy the app locally and run an AppSync GraphQL test invocation
	make deploy
	./run.sh

ws-subscribe:## Subscribe to updates via a WebSocket
	echo "Starting a WebSocket client to subscribe to GraphQL mutation operations."
	api_id=$$(awslocal appsync list-graphql-apis | jq -r '(.graphqlApis[] | select(.name=="test-api")).apiId') && \
		. .venv/bin/activate && python websocket_client.py "$$api_id"

start:
	localstack start -d

stop:
	@echo
	localstack stop

ready:
	@echo Waiting on the LocalStack container...
	@localstack wait -t 30 && echo Localstack is ready to use! || (echo Gave up waiting on LocalStack, exiting. && exit 1)

logs:
	@localstack logs > logs.txt

test-ci:
	make start install ready run; return_code=`echo $$?`;\
	make logs; make stop; exit $$return_code;

.PHONY: usage install start run stop ready logs test-ci
