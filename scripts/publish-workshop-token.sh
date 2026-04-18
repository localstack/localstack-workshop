#!/usr/bin/env bash
set -euo pipefail

BUCKET="localstack-artifacts-internal"
S3_KEY="ls-workshop/auth-token"
TOKEN_FILE=".workshop-token"

if [ -z "${LOCALSTACK_AUTH_TOKEN:-}" ]; then
  echo "Error: LOCALSTACK_AUTH_TOKEN is not set."
  exit 1
fi

echo "$LOCALSTACK_AUTH_TOKEN" > "$TOKEN_FILE"

aws s3 cp "$TOKEN_FILE" "s3://$BUCKET/$S3_KEY" \
  --acl public-read \
  --content-type "text/plain"

PUBLIC_URL="https://$BUCKET.s3.amazonaws.com/$S3_KEY"
echo "Token published: $PUBLIC_URL"

echo "Verifying download..."
DOWNLOADED=$(curl -fsSL "$PUBLIC_URL")
if [ "$DOWNLOADED" != "$LOCALSTACK_AUTH_TOKEN" ]; then
  echo "Error: downloaded token does not match. Got: '$DOWNLOADED'"
  exit 1
fi
echo "Verification passed."
echo ""
echo "Set this in devcontainer or share with participants:"
echo "  WORKSHOP_TOKEN_URL=$PUBLIC_URL"
