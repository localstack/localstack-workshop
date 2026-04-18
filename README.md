# LocalStack Workshop — AWS Community Day

Hands-on workshop: local serverless development with [LocalStack](https://localstack.cloud).

**Duration:** ~3 hours  
**Level:** Intermediate  
**Prerequisites:** Docker, Python 3.10+, VS Code (for module 03)

---

## What You'll Build

An **Order Processing Pipeline** — a realistic event-driven serverless app:

```
POST /orders
    └─▶ API Gateway
            └─▶ Lambda (order_handler)
                    ├─▶ DynamoDB  (persist order)
                    └─▶ SQS       (enqueue for processing)
                                └─▶ Lambda (order_processor)
                                        ├─▶ DynamoDB  (update status)
                                        └─▶ S3        (store receipt)
                                SQS DLQ ◀─ (on failure)
```

Everything runs **locally** via LocalStack — no AWS account needed.

---

## Modules

| # | Module | Topics | Time |
|---|--------|--------|------|
| [00](./00-setup/) | Setup | Install tools, start LocalStack, verify | 15m |
| [01](./01-serverless-app/) | Serverless App | `awslocal` CLI tour + Terraform deploy | 45m |
| [02](./02-e2e-testing/) | E2E Testing | pytest integration tests | 30m |
| [03](./03-vscode-debugging/) | Lambda Debugging | VS Code AWS Toolkit breakpoints | 30m |
| [04](./04-chaos-engineering/) | Chaos Engineering | DDB fault injection, DLQ, retries | 30m |
| [05](./05-app-inspector/) | App Inspector | Trace requests, visualize topology | 20m |
| [06](./06-ai-integration/) | AI Integration *(optional)* | LocalStack MCP + Claude Code skills | 10m |

---

## Quick Start (GitHub Codespaces)

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/localstack/localstack-workshop)

The dev container pre-installs all tools. Run the setup script to configure your auth token:

```bash
./00-setup/setup.sh
```

## Quick Start (Local)

```bash
# 1. Install dependencies
pip install localstack awscli-local terraform-local pytest

# 2. Start LocalStack
localstack start -d

# 3. Run setup
./00-setup/setup.sh
```

---

## Repo Layout

```
localstack-workshop/
├── 00-setup/              # environment setup & verification
├── 01-serverless-app/     # app code (Lambdas + Terraform) — shared by all modules
│   ├── lambdas/
│   │   ├── order_handler/
│   │   └── order_processor/
│   └── terraform/
├── 02-e2e-testing/        # pytest test suite
├── 03-vscode-debugging/   # VS Code launch configs + instructions
├── 04-chaos-engineering/  # fault injection scripts
├── 05-app-inspector/      # App Inspector walkthrough
└── 06-ai-integration/     # MCP server + LocalStack skills demo
```

All modules build on the single app deployed in `01-serverless-app/`.
