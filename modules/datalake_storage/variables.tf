variable "project_name" {
  description = "Nombre del proyecto."
  type        = string
}

variable "environment" {
  description = "Ambiente."
  type        = string
}

variable "name_prefix" {
  description = "Prefijo estándar para nombrar recursos."
  type        = string
  default     = null
}

variable "allowed_cors_origins" {
  description = "Orígenes permitidos para CORS en el bucket Raw."
  type        = list(string)
  default     = ["*"]
}

variable "allowed_api_origins" {
  description = "Orígenes permitidos para API/CORS. Variable de compatibilidad."
  type        = list(string)
  default     = []
}
