variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente del despliegue"
  type        = string
}

variable "user_pool_id" {
  description = "ID del User Pool de Cognito"
  type        = string
}

variable "client_id" {
  description = "Client ID de Cognito"
  type        = string
}

variable "user_pool_endpoint" {
  description = "Endpoint del User Pool de Cognito"
  type        = string
}

variable "integration_uri" {
  description = "Invoke ARN de la Lambda que será integrada con API Gateway"
  type        = string
}

variable "lambda_function_name" {
  description = "Nombre de la Lambda que será invocada por API Gateway"
  type        = string
}