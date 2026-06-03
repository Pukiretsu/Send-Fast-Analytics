variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente de despliegue"
  type        = string
}

variable "name_prefix" {
  description = "Prefijo para nombres de recursos"
  type        = string
}

variable "aws_region" {
  description = "Región AWS"
  type        = string
}

variable "account_id" {
  description = "ID de la cuenta AWS"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR de la VPC para Grafana"
  type        = string
}

variable "availability_zones" {
  description = "Zonas de disponibilidad para las subnets públicas"
  type        = list(string)
}

variable "allowed_grafana_cidr_blocks" {
  description = "CIDR permitidos para acceder a Grafana por el puerto 3000"
  type        = list(string)
}

variable "refined_bucket_name" {
  description = "Nombre del bucket refined/stage donde están los Parquet"
  type        = string
}

variable "refined_bucket_arn" {
  description = "ARN del bucket refined/stage donde están los Parquet"
  type        = string
}

variable "athena_results_bucket_arn" {
  description = "ARN del bucket de resultados de Athena. Si es null, el módulo crea uno nuevo."
  type        = string
  default     = null
}

variable "grafana_admin_user" {
  description = "Usuario administrador de Grafana"
  type        = string
}

variable "grafana_admin_password" {
  description = "Password administrador de Grafana"
  type        = string
  sensitive   = true
}

variable "grafana_instance_type" {
  description = "Tipo de instancia EC2 para Grafana"
  type        = string
}

variable "grafana_volume_size" {
  description = "Tamaño del volumen raíz en GB"
  type        = number
}

variable "ssh_cidr_blocks" {
  description = "CIDR permitidos para SSH"
  type        = list(string)
  default     = []
}

variable "key_name" {
  description = "Nombre del Key Pair para SSH"
  type        = string
  default     = null
}