data "aws_caller_identity" "current" {}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_src"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_dynamodb_table" "orders" {
  name         = "${var.project_name}-${var.environment}-orders"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "order_id"

  attribute {
    name = "order_id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

}

resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-${var.environment}-process-orders-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-process-orders"
  retention_in_days = 30
}

resource "aws_iam_policy" "lambda" {
  name        = "${var.project_name}-${var.environment}-process-orders-policy"
  description = "Permisos mínimos para procesar Raw, escribir Trusted y DynamoDB."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadRawOrders"
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${var.raw_bucket_arn}/orders/*"
      },
      {
        Sid    = "WriteTrustedOrders"
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${var.trusted_bucket_arn}/orders/trusted/*"
      },
      {
        Sid    = "WriteDynamoDBOrders"
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DescribeTable"
        ]
        Resource = aws_dynamodb_table.orders.arn
      },
      {
        Sid    = "WriteLambdaLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.lambda.arn}:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

resource "aws_lambda_function" "process_orders" {
  function_name    = "${var.project_name}-${var.environment}-process-orders"
  role             = aws_iam_role.lambda.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = var.lambda_runtime
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 60
  memory_size      = 256

  environment {
    variables = {
      TABLE_NAME     = aws_dynamodb_table.orders.name
      TRUSTED_BUCKET = var.trusted_bucket_name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda,
    aws_cloudwatch_log_group.lambda
  ]
}

resource "aws_lambda_permission" "allow_s3_raw" {
  statement_id  = "AllowExecutionFromS3Raw"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_orders.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.raw_bucket_arn
}
