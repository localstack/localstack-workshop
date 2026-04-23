.DEFAULT_GOAL := help
TERRAFORM_DIR  := 01-serverless-app/terraform
ECR_REGISTRY   := 000000000000.dkr.ecr.us-east-1.localhost.localstack.cloud:4566
FULFILLMENT_DIR := 01-serverless-app/services/fulfillment

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage: make \033[36m<target>\033[0m\n\nTargets:\n"} \
	  /^[a-zA-Z_-]+:.*##/ { printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

# ── LocalStack ────────────────────────────────────────────────────────────────

start: ## Start LocalStack in the background
	LOCALSTACK_APPINSPECTOR_ENABLE=1 LOCALSTACK_APPINSPECTOR_DEV_ENABLE=1 localstack start -d

debug-start: ## Start LocalStack with Lambda debug mode enabled (port 19891)
	LOCALSTACK_APPINSPECTOR_ENABLE=1 LOCALSTACK_APPINSPECTOR_DEV_ENABLE=1 \
	  LAMBDA_DEBUG_MODE=1 \
	  LAMBDA_DEBUG_MODE_CONFIG_PATH=$(PWD)/.localstack/lambda_debug_mode.yaml localstack start -d

hot-reload: ## Switch order-handler to hot-reload mode (edits take effect immediately)
	awslocal lambda update-function-code \
	  --function-name order-handler \
	  --s3-bucket hot-reload \
	  --s3-key $(PWD)/01-serverless-app/lambdas/order_handler

hot-reload-off: ## Restore order-handler to the packaged ZIP (disable hot reload)
	cd $(TERRAFORM_DIR) && tflocal apply -auto-approve -target=aws_lambda_function.order_handler

stop: ## Stop LocalStack
	localstack stop

status: ## Show LocalStack health and running services
	curl -s http://localhost:4566/_localstack/health | python3 -m json.tool

logs: ## Tail LocalStack logs
	localstack logs -f

setup: ## Fetch auth token and start LocalStack (runs 00-setup/setup.sh)
	bash 00-setup/setup.sh

# ── Deploy ────────────────────────────────────────────────────────────────────

init: ## Initialise Terraform (only needed once)
	cd $(TERRAFORM_DIR) && tflocal init

build: ## Build and push the fulfillment service image to local ECR
	awslocal ecr get-login-password | \
	  docker login --username AWS --password-stdin $(ECR_REGISTRY)
	docker build -t $(ECR_REGISTRY)/fulfillment:latest $(FULFILLMENT_DIR)
	docker push $(ECR_REGISTRY)/fulfillment:latest

deploy: ## Deploy the full app to LocalStack via Terraform, then build the fulfillment image
	@[ -d $(TERRAFORM_DIR)/.terraform ] || (cd $(TERRAFORM_DIR) && tflocal init)
	cd $(TERRAFORM_DIR) && tflocal apply -auto-approve
	$(MAKE) build

destroy: ## Tear down all deployed resources
	cd $(TERRAFORM_DIR) && tflocal destroy -auto-approve

redeploy: destroy deploy ## Tear down and redeploy from scratch

outputs: ## Print Terraform outputs (API endpoint, website URL)
	cd $(TERRAFORM_DIR) && tflocal output

# ── Test ──────────────────────────────────────────────────────────────────────

test: ## Run end-to-end integration tests
	cd 02-e2e-testing && pytest tests/ -v

test-fast: ## Run tests, stop on first failure
	cd 02-e2e-testing && pytest tests/ -v -x

# ── App ───────────────────────────────────────────────────────────────────────

open-ui: ## Open the orders UI in the default browser
	@URL=$$(cd $(TERRAFORM_DIR) && tflocal output -raw website_url 2>/dev/null) && \
	  echo "Opening $$URL" && open "$$URL" || xdg-open "$$URL"

api-endpoint: ## Print the API Gateway endpoint
	@cd $(TERRAFORM_DIR) && tflocal output -raw api_endpoint

# ── Chaos ─────────────────────────────────────────────────────────────────────

inject-fault: ## Inject DynamoDB throttling fault (breaks order_processor)
	curl -s -X POST http://localhost:4566/_localstack/chaos/faults \
	  -H "Content-Type: application/json" \
	  -d @04-chaos-engineering/faults/ddb-throttle-localstack.json | python3 -m json.tool

remove-fault: ## Remove all active fault injections
	curl -s -X POST http://localhost:4566/_localstack/chaos/faults \
	  -H "Content-Type: application/json" -d '[]'

replay-dlq: ## Replay messages from the DLQ back to the main queue
	awslocal sqs receive-message \
	  --queue-url http://localhost:4566/000000000000/orders-dlq \
	  --max-number-of-messages 10 | python3 04-chaos-engineering/scripts/replay_dlq.py

# ── IAM enforcement ───────────────────────────────────────────────────────────

iam-enforce: ## Enable IAM policy enforcement — order creation now fails (missing PutItem)
	curl -s -X POST http://localhost:4566/_aws/iam/config \
	  -H "Content-Type: application/json" \
	  -d '{"state":"ENFORCED"}' | python3 -m json.tool

iam-off: ## Disable IAM enforcement (permissive mode, default)
	curl -s -X POST http://localhost:4566/_aws/iam/config \
	  -H "Content-Type: application/json" \
	  -d '{"state":"ENGINE_ONLY"}' | python3 -m json.tool

iam-fix: ## Grant missing dynamodb:PutItem to the Lambda role — fixes order creation
	awslocal iam put-role-policy \
	  --role-name lambda-exec-role \
	  --policy-name order-handler-putitem \
	  --policy-document file://03-iam-enforcement/policies/lambda-putitem-grant.json
	@echo "Permission granted — order creation should work now"

iam-status: ## Show current IAM enforcement state and Lambda role policies
	@echo "=== IAM enforcement ===" && \
	  curl -s http://localhost:4566/_aws/iam/config | python3 -m json.tool
	@echo "=== Lambda role policies ===" && \
	  awslocal iam list-role-policies --role-name lambda-exec-role

# ── Token ─────────────────────────────────────────────────────────────────────

publish-token: ## Upload LOCALSTACK_AUTH_TOKEN to S3 for workshop participants
	bash scripts/publish-workshop-token.sh

.PHONY: help start stop status logs setup debug-start hot-reload hot-reload-off \
        init build deploy destroy redeploy outputs \
        test test-fast open-ui api-endpoint inject-fault remove-fault replay-dlq \
        iam-enforce iam-off iam-fix iam-status publish-token
