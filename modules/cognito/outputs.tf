output "user_pool_id" {
  value       = aws_cognito_user_pool.this.id
  description = "ID del User Pool de Cognito"
}

output "user_pool_endpoint" {
  value       = aws_cognito_user_pool.this.endpoint
  description = "Endpoint del proveedor de identidad para el Issuer de API Gateway"
}

output "client_id" {
  value       = aws_cognito_user_pool_client.this.id
  description = "ID del Client Application"
}

output "client_secret" {
  value     = aws_cognito_user_pool_client.this.client_secret
  sensitive = true # Evita que el secreto se imprima en texto plano en la terminal
}
