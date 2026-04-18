# Module 00 — Setup

Verify your environment and start LocalStack before proceeding to module 01.

---

## 1. Auth Token

Run the setup script — it fetches today's workshop token automatically:

```bash
./00-setup/setup.sh
```

If you're running this outside the workshop, set your own token:

```bash
export LOCALSTACK_AUTH_TOKEN=<your-token>
```

---

## 2. Start LocalStack

```bash
localstack start -d
```

Wait until you see `Ready.` in the logs (`localstack logs -f`).

---

## 3. Verify

```bash
awslocal s3 ls                         # should return empty list (no error)
curl -s http://localhost:4566/_localstack/health | python3 -m json.tool
```

You should see `"running": true` and a list of available services.

---

## Installed Tools Checklist

| Tool | Purpose | Check |
|------|---------|-------|
| `localstack` | Run AWS locally | `localstack --version` |
| `awslocal` | AWS CLI → LocalStack | `awslocal --version` |
| `tflocal` | Terraform → LocalStack | `tflocal --version` |
| `pytest` | Integration tests | `pytest --version` |
| Docker | LocalStack runtime | `docker info` |

---

Next: [Module 01 — Serverless App](../01-serverless-app/README.md)
