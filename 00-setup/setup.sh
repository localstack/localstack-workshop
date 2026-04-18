#!/usr/bin/env bash
set -euo pipefail

# Workshop auth token endpoint — organizer publishes token here on event day.
# The URL points to a time-limited S3 object; replace before each workshop.
TOKEN_URL="${WORKSHOP_TOKEN_URL:-https://localstack-artifacts-internal.s3.amazonaws.com/ls-workshop/auth-token}"

if [ -z "${LOCALSTACK_AUTH_TOKEN:-}" ]; then
  echo "Fetching LocalStack auth token from: $TOKEN_URL"
  TOKEN=$(curl -fsSL "$TOKEN_URL")
  export LOCALSTACK_AUTH_TOKEN="$TOKEN"
  echo "export LOCALSTACK_AUTH_TOKEN=$TOKEN" >> "${HOME}/.bashrc"
  echo "export LOCALSTACK_AUTH_TOKEN=$TOKEN" >> "${HOME}/.zshrc" 2>/dev/null || true
  echo "Token set."
else
  echo "Using existing LOCALSTACK_AUTH_TOKEN."
fi

echo ""
echo "Configuring AWS CLI default profile for LocalStack..."
mkdir -p "${HOME}/.aws"
cat > "${HOME}/.aws/credentials" << 'EOF'
[default]
aws_access_key_id = test
aws_secret_access_key = test
EOF
cat > "${HOME}/.aws/config" << 'EOF'
[default]
region = us-east-1
endpoint_url = http://localhost:4566
output = json
EOF
echo "AWS CLI profile configured."

echo ""
echo "Starting LocalStack..."
localstack start -d

echo ""
echo "Waiting for LocalStack to be ready..."
localstack wait -t 60

echo ""
echo "Verifying..."
aws s3 ls > /dev/null && echo "OK: aws CLI connected (via default profile)"
curl -sf http://localhost:4566/_localstack/health | python3 -m json.tool | grep -q '"running"' && echo "OK: health check passed"

echo ""
echo "Setup complete. Proceed to module 01."
