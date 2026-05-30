data "aws_caller_identity" "current" {}

resource "aws_iam_role" "api_gateway_s3" {
  name = "${var.project_name}-${var.environment}-apigw-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "api_gateway_s3_put" {
  name        = "${var.project_name}-${var.environment}-apigw-s3-put-policy"
  description = "Permite a API Gateway escribir únicamente objetos de órdenes en Raw."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "PutOrdersOnly"
      Effect = "Allow"
      Action = [
        "s3:PutObject"
      ]
      Resource = "${var.raw_bucket_arn}/orders/*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_s3_put" {
  role       = aws_iam_role.api_gateway_s3.name
  policy_arn = aws_iam_policy.api_gateway_s3_put.arn
}

resource "aws_api_gateway_rest_api" "orders" {
  name        = "${var.project_name}-${var.environment}-orders-api"
  description = "REST API para depositar órdenes JSON directamente en S3 Raw."

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "orders" {
  rest_api_id = aws_api_gateway_rest_api.orders.id
  parent_id   = aws_api_gateway_rest_api.orders.root_resource_id
  path_part   = "orders"
}

resource "aws_api_gateway_method" "post_orders" {
  rest_api_id      = aws_api_gateway_rest_api.orders.id
  resource_id      = aws_api_gateway_resource.orders.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "s3_put" {
  rest_api_id             = aws_api_gateway_rest_api.orders.id
  resource_id             = aws_api_gateway_resource.orders.id
  http_method             = aws_api_gateway_method.post_orders.http_method
  integration_http_method = "PUT"
  type                    = "AWS"
  credentials             = aws_iam_role.api_gateway_s3.arn
  uri                     = "arn:aws:apigateway:${var.aws_region}:s3:path/${var.raw_bucket_name}/orders/$context.requestId.json"
  passthrough_behavior    = "WHEN_NO_MATCH"
  content_handling        = "CONVERT_TO_TEXT"

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/json'"
  }

  request_templates = {
    "application/json" = "$input.body"
  }

  depends_on = [
    aws_iam_role_policy_attachment.api_gateway_s3_put
  ]
}

resource "aws_api_gateway_method_response" "post_200" {
  rest_api_id = aws_api_gateway_rest_api.orders.id
  resource_id = aws_api_gateway_resource.orders.id
  http_method = aws_api_gateway_method.post_orders.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "post_200" {
  rest_api_id = aws_api_gateway_rest_api.orders.id
  resource_id = aws_api_gateway_resource.orders.id
  http_method = aws_api_gateway_method.post_orders.http_method
  status_code = aws_api_gateway_method_response.post_200.status_code

  response_templates = {
    "application/json" = jsonencode({
      message = "Order received"
    })
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  depends_on = [
    aws_api_gateway_integration.s3_put
  ]
}

resource "aws_api_gateway_method" "options_orders" {
  rest_api_id   = aws_api_gateway_rest_api.orders.id
  resource_id   = aws_api_gateway_resource.orders.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.orders.id
  resource_id = aws_api_gateway_resource.orders.id
  http_method = aws_api_gateway_method.options_orders.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration" "options_mock" {
  rest_api_id = aws_api_gateway_rest_api.orders.id
  resource_id = aws_api_gateway_resource.orders.id
  http_method = aws_api_gateway_method.options_orders.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_integration_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.orders.id
  resource_id = aws_api_gateway_resource.orders.id
  http_method = aws_api_gateway_method.options_orders.http_method
  status_code = aws_api_gateway_method_response.options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_integration.options_mock
  ]
}

resource "aws_api_gateway_deployment" "orders" {
  rest_api_id = aws_api_gateway_rest_api.orders.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.orders.id,
      aws_api_gateway_method.post_orders.id,
      aws_api_gateway_integration.s3_put.id,
      aws_api_gateway_method.options_orders.id,
      aws_api_gateway_integration.options_mock.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration_response.post_200,
    aws_api_gateway_integration_response.options_200
  ]
}

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.orders.id
  rest_api_id   = aws_api_gateway_rest_api.orders.id
  stage_name    = var.environment
}
