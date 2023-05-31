# hello world with a s3 static website

https://docs.localstack.cloud/tutorials/s3-static-website-terraform/

# create the bucket
awslocal s3api create-bucket --bucket testwebsite

# attach the policy
awslocal s3api put-bucket-policy --bucket testwebsite --policy file://bucket-policy.json

# sync the content to the bucket
awslocal s3 sync ./ s3://testwebsite

# enable static hosting
awslocal s3 website s3://testwebsite/ --index-document index.html

# goto
http://testwebsite.s3-website.localhost.localstack.cloud:4566/

Note: If you are executing in Github Codespaces, you can right click on port 4566, then "Copy Local Address", and then append the suffix `/testwebsite/index.html` to the URL. For example, the final URL may look something like this:
https://yourusername-vigilant-umbrella-q94554wwv-4566.preview.app.github.dev/testwebsite/index.html
