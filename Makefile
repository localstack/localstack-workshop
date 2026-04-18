.DEFAULT_GOAL := help
TERRAFORM_DIR := 01-serverless-app/terraform

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage: make \033[36m<target>\033[0m\n\nTargets:\n"} \
	  /^[a-zA-Z_-]+:.*##/ { printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

# ── LocalStack ────────────────────────────────────────────────────────────────

start: ## Start LocalStack in the background
	LOCALSTACK_APPINSPECTOR_ENABLE=1 LOCALSTACK_APPINSPECTOR_DEV_ENABLE=1 localstack start -d

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

deploy: ## Deploy the full app to LocalStack via Terraform
	@[ -d $(TERRAFORM_DIR)/.terraform ] || (cd $(TERRAFORM_DIR) && tflocal init)
	cd $(TERRAFORM_DIR) && tflocal apply -auto-approve

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

# ── Token ─────────────────────────────────────────────────────────────────────

publish-token: ## Upload LOCALSTACK_AUTH_TOKEN to S3 for workshop participants
	bash scripts/publish-workshop-token.sh

.PHONY: help start stop status logs setup init deploy destroy redeploy outputs \
        test test-fast open-ui api-endpoint inject-fault remove-fault replay-dlq \
        publish-token
