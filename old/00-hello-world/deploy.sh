#!/bin/bash

awslocal s3api create-bucket --bucket testwebsite

awslocal s3api put-bucket-policy --bucket testwebsite --policy file://bucket-policy.json

awslocal s3 sync ./ s3://testwebsite

awslocal s3 website s3://testwebsite/ --index-document index.html

echo "Visit http://testwebsite.s3-website.localhost.localstack.cloud:4566/"
echo
echo "If you're using Github Codespaces, find the public endpoint for port 4566, then visit https://<your-space>-4566.preview.app.github.dev/testwebsite/index.html"
