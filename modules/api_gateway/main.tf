# ---------------------------------------------------------
# 🌐 1. Crear API Gateway HTTP
# ---------------------------------------------------------
resource "aws_apigatewayv2_api" "this" {
  name          = "${var.project_name}-${var.environment}-http-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["content-type", "authorization"]
    max_age       = 300
  }
}

# ---------------------------------------------------------
# 🚀 2. Stage automático $default
# ---------------------------------------------------------
resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true
}

# ---------------------------------------------------------
# 🔐 3. Autorizador JWT con Cognito
# ---------------------------------------------------------
resource "aws_apigatewayv2_authorizer" "cognito_jwt" {
  api_id           = aws_apigatewayv2_api.this.id
  name             = "${var.project_name}-${var.environment}-cognito-jwt-authorizer"
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    issuer   = "https://${var.user_pool_endpoint}"
    audience = [var.client_id]
  }
}

# ---------------------------------------------------------
# ⚙️ 4. Integración con Lambda
# ---------------------------------------------------------
resource "aws_apigatewayv2_integration" "lambda_ingesta" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = var.integration_uri
  payload_format_version = "2.0"
}

# ---------------------------------------------------------
# 🛣️ 5. Ruta POST /ingesta protegida con Cognito
# ---------------------------------------------------------
resource "aws_apigatewayv2_route" "post_ingesta" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /ingesta"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_jwt.id

  target = "integrations/${aws_apigatewayv2_integration.lambda_ingesta.id}"
}

# ---------------------------------------------------------
# 🔓 6. Permiso para que API Gateway invoque Lambda
# ---------------------------------------------------------
resource "aws_lambda_permission" "allow_api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke-${var.environment}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}
