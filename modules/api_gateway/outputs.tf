output "api_id" {
  description = "ID del API Gateway HTTP"
  value       = aws_apigatewayv2_api.this.id
}

output "api_endpoint" {
  description = "Endpoint público del API Gateway"
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "execution_arn" {
  description = "Execution ARN del API Gateway"
  value       = aws_apigatewayv2_api.this.execution_arn
}

output "ingesta_route" {
  description = "Ruta de ingesta"
  value       = "${aws_apigatewayv2_api.this.api_endpoint}/ingesta"
}
