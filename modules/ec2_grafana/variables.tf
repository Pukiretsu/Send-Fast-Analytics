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
  default     = []
}

variable "refined_bucket_name" {
  description = "Nombre del bucket refined/stage donde están los Parquet"
  type        = string
}

variable "refined_bucket_arn" {
  description = "ARN del bucket refined/stage donde están los Parquet"
  type        = string
}

variable "create_athena_results_bucket" {
  description = "Define si el módulo de Grafana debe crear un bucket propio para resultados de Athena."
  type        = bool
  default     = false
}

variable "athena_results_bucket_name" {
  description = "Nombre del bucket existente de resultados de Athena cuando create_athena_results_bucket es false."
  type        = string
  default     = null
}

variable "athena_results_bucket_arn" {
  description = "ARN del bucket de resultados de Athena. Debe informarse cuando create_athena_results_bucket es false."
  type        = string
  default     = null
}

variable "grafana_admin_secret_arn" {
  description = "ARN de AWS Secrets Manager con JSON {username,password} para configurar el administrador inicial de Grafana."
  type        = string
}

variable "glue_database_name" {
  description = "Base de datos Glue que usará el datasource de Athena en Grafana"
  type        = string
}

variable "athena_workgroup_name" {
  description = "Workgroup de Athena que usará Grafana"
  type        = string
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
