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

variable "raw_bucket_id" {
  description = "ID o nombre del bucket Raw. Se mantiene para compatibilidad."
  type        = string
  default     = null
}

variable "raw_bucket_name" {
  description = "Nombre del bucket Raw."
  type        = string
}

variable "raw_bucket_arn" {
  description = "ARN del bucket Raw."
  type        = string
}

variable "api_gateway_invoke_url" {
  description = "URL base de API Gateway."
  type        = string
}
