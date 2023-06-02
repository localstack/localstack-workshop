# Hello World in LocalStack

This simple serverless app is the Hello World of LocalStack.
It will deploy an s3 static website with a simple _"Hello World"_.

For more information, visit our [docs](https://docs.localstack.cloud/tutorials/s3-static-website-terraform/).

## How to run

Simply start LocalStack with `localstack start -d` and then run the `deploy.sh` script.

**Note**: If you are executing in Github Codespaces, you can right-click on port 4566, then "Copy Local Address", and then append the suffix /testwebsite/index.html to the URL. For example, the final URL may look something like this: https://yourusername-vigilant-umbrella-q94554wwv-4566.preview.app.github.dev/testwebsite/index.html