terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

# ── VPC (required for FARGATE awsvpc network mode) ────────────────────────────

resource "aws_default_vpc" "default" {}

resource "aws_default_subnet" "default" {
  availability_zone = "us-east-1a"
}

# ── DynamoDB ──────────────────────────────────────────────────────────────────

resource "aws_dynamodb_table" "products" {
  name         = "products"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "product_id"

  attribute {
    name = "product_id"
    type = "S"
  }
}

locals {
  products = [
    { product_id = "ls-tshirt",      name = "LocalStack T-Shirt",    description = "Classic logo tee",             price = "24.99" },
    { product_id = "ls-hoodie",      name = "LocalStack Hoodie",     description = "Warm & cloud-native",          price = "49.99" },
    { product_id = "ls-cap",         name = "LocalStack Cap",        description = "Keep the sun off your stack",  price = "19.99" },
    { product_id = "ls-mug",         name = "LocalStack Mug",        description = "Fill it with local coffee",    price = "14.99" },
    { product_id = "ls-stickers",    name = "Sticker Pack",          description = "10 cloud-native stickers",     price = "4.99"  },
    { product_id = "ls-socks",       name = "LocalStack Socks",      description = "Deploy faster on your feet",   price = "9.99"  },
  ]
}

resource "aws_dynamodb_table_item" "products" {
  for_each   = { for p in local.products : p.product_id => p }
  table_name = aws_dynamodb_table.products.name
  hash_key   = aws_dynamodb_table.products.hash_key

  item = jsonencode({
    product_id  = { S = each.value.product_id }
    name        = { S = each.value.name }
    description = { S = each.value.description }
    price       = { N = each.value.price }
  })
}

resource "aws_dynamodb_table" "orders" {
  name         = "orders"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "order_id"

  attribute {
    name = "order_id"
    type = "S"
  }
}

# ── ECR ───────────────────────────────────────────────────────────────────────

resource "aws_ecr_repository" "fulfillment" {
  name = "fulfillment"
}

# ── ECS ───────────────────────────────────────────────────────────────────────

resource "aws_ecs_cluster" "main" {
  name = "workshop"
}

resource "aws_iam_role" "ecs_execution" {
  name = "ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task" {
  name = "ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "ecs_task" {
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:UpdateItem"]
        Resource = aws_dynamodb_table.orders.arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${aws_s3_bucket.receipts.arn}/*"
      }
    ]
  })
}

resource "aws_ecs_task_definition" "fulfillment" {
  family                   = "fulfillment"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name  = "fulfillment"
    image = "${aws_ecr_repository.fulfillment.repository_url}:latest"
    environment = [
      { name = "ORDERS_TABLE",         value = aws_dynamodb_table.orders.name },
      { name = "RECEIPTS_BUCKET",      value = aws_s3_bucket.receipts.bucket },
      { name = "AWS_ENDPOINT_URL",     value = "http://localhost.localstack.cloud:4566" },
      { name = "AWS_DEFAULT_REGION",   value = "us-east-1" },
      { name = "AWS_ACCESS_KEY_ID",    value = "test" },
      { name = "AWS_SECRET_ACCESS_KEY", value = "test" },
    ]
  }])
}

# ── S3 ────────────────────────────────────────────────────────────────────────

resource "aws_s3_bucket" "receipts" {
  bucket = "order-receipts"
}

# ── SQS ───────────────────────────────────────────────────────────────────────

resource "aws_sqs_queue" "orders_dlq" {
  name = "orders-dlq"
}

resource "aws_sqs_queue" "orders" {
  name = "orders-queue"

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.orders_dlq.arn
    maxReceiveCount     = 3
  })
}

# ── IAM ───────────────────────────────────────────────────────────────────────

resource "aws_iam_role" "lambda_exec" {
  name = "lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # dynamodb:PutItem intentionally omitted — see 03-iam-enforcement for the IAM demo
        Effect   = "Allow"
        Action   = ["dynamodb:UpdateItem", "dynamodb:GetItem", "dynamodb:Scan"]
        Resource = [aws_dynamodb_table.orders.arn, aws_dynamodb_table.products.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["sqs:SendMessage", "sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        Resource = [aws_sqs_queue.orders.arn, aws_sqs_queue.orders_dlq.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject"]
        Resource = "${aws_s3_bucket.receipts.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = "states:StartExecution"
        Resource = local.state_machine_arn
      }
    ]
  })
}

resource "aws_iam_role" "sfn_exec" {
  name = "sfn-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "states.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "sfn_policy" {
  role = aws_iam_role.sfn_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "lambda:InvokeFunction"
        Resource = aws_lambda_function.order_processor.arn
      },
      {
        Effect   = "Allow"
        Action   = ["ecs:RunTask", "ecs:StopTask", "ecs:DescribeTasks"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = [aws_iam_role.ecs_execution.arn, aws_iam_role.ecs_task.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["events:PutTargets", "events:PutRule", "events:DescribeRule"]
        Resource = "*"
      }
    ]
  })
}

# ── Lambda: order_handler ─────────────────────────────────────────────────────

data "archive_file" "order_handler" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/order_handler"
  output_path = "${path.module}/.build/order_handler.zip"
}

resource "aws_lambda_function" "order_handler" {
  function_name    = "order-handler"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.order_handler.output_path
  source_code_hash = data.archive_file.order_handler.output_base64sha256

  environment {
    variables = {
      ORDERS_TABLE     = aws_dynamodb_table.orders.name
      PRODUCTS_TABLE   = aws_dynamodb_table.products.name
      ORDERS_QUEUE_URL = aws_sqs_queue.orders.url
      ORDERS_DLQ_URL   = aws_sqs_queue.orders_dlq.url
    }
  }
}

# ── Lambda: order_processor ───────────────────────────────────────────────────

data "archive_file" "order_processor" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/order_processor"
  output_path = "${path.module}/.build/order_processor.zip"
}

resource "aws_lambda_function" "order_processor" {
  function_name    = "order-processor"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.order_processor.output_path
  source_code_hash = data.archive_file.order_processor.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      ORDERS_TABLE      = aws_dynamodb_table.orders.name
      STATE_MACHINE_ARN = local.state_machine_arn
    }
  }
}

# ── Step Functions ────────────────────────────────────────────────────────────

resource "aws_sfn_state_machine" "order_processing" {
  name     = "order-processing"
  role_arn = aws_iam_role.sfn_exec.arn

  definition = jsonencode({
    StartAt = "ValidateOrder"
    States = {
      ValidateOrder = {
        Type     = "Task"
        Resource = aws_lambda_function.order_processor.arn
        Parameters = {
          "step"    = "validate"
          "order.$" = "$.order"
        }
        ResultPath = "$.order"
        Catch = [{ ErrorEquals = ["States.ALL"], Next = "HandleFailure", ResultPath = "$.error" }]
        Next = "WaitForPayment"
      }
      WaitForPayment = {
        Type    = "Wait"
        Seconds = 3
        Next    = "ProcessPayment"
      }
      ProcessPayment = {
        Type     = "Task"
        Resource = aws_lambda_function.order_processor.arn
        Parameters = {
          "step"    = "process_payment"
          "order.$" = "$.order"
        }
        ResultPath = "$.order"
        Catch = [{ ErrorEquals = ["States.ALL"], Next = "HandleFailure", ResultPath = "$.error" }]
        Next = "WaitForFulfillment"
      }
      WaitForFulfillment = {
        Type    = "Wait"
        Seconds = 3
        Next    = "FulfillOrder"
      }
      FulfillOrder = {
        Type     = "Task"
        Resource = "arn:aws:states:::ecs:runTask.sync"
        Parameters = {
          LaunchType     = "FARGATE"
          Cluster        = aws_ecs_cluster.main.arn
          TaskDefinition = aws_ecs_task_definition.fulfillment.arn
          NetworkConfiguration = {
            AwsvpcConfiguration = {
              Subnets        = [aws_default_subnet.default.id]
              AssignPublicIp = "ENABLED"
            }
          }
          Overrides = {
            ContainerOverrides = [{
              Name = "fulfillment"
              Environment = [
                { "Name" = "ORDER_ID", "Value.$" = "$.order.order_id" }
              ]
            }]
          }
        }
        ResultPath = null
        Catch = [{ ErrorEquals = ["States.ALL"], Next = "HandleFailure", ResultPath = "$.error" }]
        End = true
      }
      HandleFailure = {
        Type     = "Task"
        Resource = aws_lambda_function.order_processor.arn
        Parameters = {
          "step"    = "handle_failure"
          "order.$" = "$.order"
        }
        ResultPath = "$.order"
        End = true
      }
    }
  })
}

resource "aws_lambda_event_source_mapping" "sqs_to_processor" {
  event_source_arn = aws_sqs_queue.orders.arn
  function_name    = aws_lambda_function.order_processor.arn
  batch_size       = 5
}

# ── API Gateway ───────────────────────────────────────────────────────────────

resource "aws_api_gateway_rest_api" "orders_api" {
  name = "orders-api"
  tags = {
    "_custom_id_" = "workshop"
  }
}

resource "aws_api_gateway_resource" "orders" {
  rest_api_id = aws_api_gateway_rest_api.orders_api.id
  parent_id   = aws_api_gateway_rest_api.orders_api.root_resource_id
  path_part   = "orders"
}

resource "aws_api_gateway_method" "post_order" {
  rest_api_id   = aws_api_gateway_rest_api.orders_api.id
  resource_id   = aws_api_gateway_resource.orders.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "get_orders" {
  rest_api_id   = aws_api_gateway_rest_api.orders_api.id
  resource_id   = aws_api_gateway_resource.orders.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "options_orders" {
  rest_api_id   = aws_api_gateway_rest_api.orders_api.id
  resource_id   = aws_api_gateway_resource.orders.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_order_handler" {
  rest_api_id             = aws_api_gateway_rest_api.orders_api.id
  resource_id             = aws_api_gateway_resource.orders.id
  http_method             = aws_api_gateway_method.post_order.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.order_handler.invoke_arn
}

resource "aws_api_gateway_integration" "get_orders_handler" {
  rest_api_id             = aws_api_gateway_rest_api.orders_api.id
  resource_id             = aws_api_gateway_resource.orders.id
  http_method             = aws_api_gateway_method.get_orders.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.order_handler.invoke_arn
}

resource "aws_api_gateway_integration" "options_order_handler" {
  rest_api_id             = aws_api_gateway_rest_api.orders_api.id
  resource_id             = aws_api_gateway_resource.orders.id
  http_method             = aws_api_gateway_method.options_orders.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.order_handler.invoke_arn
}

resource "aws_api_gateway_resource" "products" {
  rest_api_id = aws_api_gateway_rest_api.orders_api.id
  parent_id   = aws_api_gateway_rest_api.orders_api.root_resource_id
  path_part   = "products"
}

resource "aws_api_gateway_method" "get_products" {
  rest_api_id   = aws_api_gateway_rest_api.orders_api.id
  resource_id   = aws_api_gateway_resource.products.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "options_products" {
  rest_api_id   = aws_api_gateway_rest_api.orders_api.id
  resource_id   = aws_api_gateway_resource.products.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_products_handler" {
  rest_api_id             = aws_api_gateway_rest_api.orders_api.id
  resource_id             = aws_api_gateway_resource.products.id
  http_method             = aws_api_gateway_method.get_products.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.order_handler.invoke_arn
}

resource "aws_api_gateway_integration" "options_products_handler" {
  rest_api_id             = aws_api_gateway_rest_api.orders_api.id
  resource_id             = aws_api_gateway_resource.products.id
  http_method             = aws_api_gateway_method.options_products.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.order_handler.invoke_arn
}

resource "aws_api_gateway_resource" "orders_replay" {
  rest_api_id = aws_api_gateway_rest_api.orders_api.id
  parent_id   = aws_api_gateway_resource.orders.id
  path_part   = "replay"
}

resource "aws_api_gateway_method" "post_replay" {
  rest_api_id   = aws_api_gateway_rest_api.orders_api.id
  resource_id   = aws_api_gateway_resource.orders_replay.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "options_replay" {
  rest_api_id   = aws_api_gateway_rest_api.orders_api.id
  resource_id   = aws_api_gateway_resource.orders_replay.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_replay_handler" {
  rest_api_id             = aws_api_gateway_rest_api.orders_api.id
  resource_id             = aws_api_gateway_resource.orders_replay.id
  http_method             = aws_api_gateway_method.post_replay.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.order_handler.invoke_arn
}

resource "aws_api_gateway_integration" "options_replay_handler" {
  rest_api_id             = aws_api_gateway_rest_api.orders_api.id
  resource_id             = aws_api_gateway_resource.orders_replay.id
  http_method             = aws_api_gateway_method.options_replay.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.order_handler.invoke_arn
}

resource "aws_lambda_permission" "apigw" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.order_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.orders_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "orders_api" {
  rest_api_id = aws_api_gateway_rest_api.orders_api.id
  stage_name  = "local"

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_integration.post_order_handler.id,
      aws_api_gateway_integration.get_orders_handler.id,
      aws_api_gateway_integration.options_order_handler.id,
      aws_api_gateway_integration.post_replay_handler.id,
      aws_api_gateway_integration.options_replay_handler.id,
      aws_api_gateway_integration.get_products_handler.id,
      aws_api_gateway_integration.options_products_handler.id,
    ]))
  }

  depends_on = [
    aws_api_gateway_integration.post_order_handler,
    aws_api_gateway_integration.get_orders_handler,
    aws_api_gateway_integration.options_order_handler,
    aws_api_gateway_integration.post_replay_handler,
    aws_api_gateway_integration.options_replay_handler,
    aws_api_gateway_integration.get_products_handler,
    aws_api_gateway_integration.options_products_handler,
  ]
}

# ── S3 Website ────────────────────────────────────────────────────────────────

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  api_id            = "workshop"
  api_endpoint      = "http://localhost:4566/restapis/${local.api_id}/local/_user_request_"
  state_machine_arn = "arn:aws:states:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stateMachine:order-processing"
}

resource "aws_s3_bucket" "website" {
  bucket = "orders-ui"
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket                  = aws_s3_bucket.website.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id
  index_document { suffix = "index.html" }
}

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.website.arn}/*"
    }]
  })
  depends_on = [aws_s3_bucket_public_access_block.website]
}

resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  source       = "${path.module}/../website/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/../website/index.html")
}

output "api_endpoint" {
  value = local.api_endpoint
}

output "website_url" {
  value = "http://localhost:4566/orders-ui/index.html"
}
