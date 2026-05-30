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
}

variable "aws_region" {
  description = "Región AWS."
  type        = string
}

variable "account_id" {
  description = "ID de la cuenta AWS."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR de la VPC para Grafana EC2."
  type        = string
}

variable "availability_zones" {
  description = "Zonas de disponibilidad."
  type        = list(string)
}

variable "allowed_grafana_cidr_blocks" {
  description = "CIDR permitidos para acceder a Grafana por puerto 3000."
  type        = list(string)
}

variable "refined_bucket_name" {
  description = "Nombre del bucket Refined."
  type        = string
}

variable "refined_bucket_arn" {
  description = "ARN del bucket Refined."
  type        = string
}

variable "grafana_admin_user" {
  description = "Usuario administrador inicial de Grafana."
  type        = string
}

variable "grafana_admin_password" {
  description = "Contraseña administradora inicial de Grafana."
  type        = string
  sensitive   = true
}

variable "grafana_instance_type" {
  description = "Tipo de instancia EC2 para Grafana."
  type        = string
  default     = "t3.micro"
}

variable "grafana_volume_size" {
  description = "Tamaño del volumen raíz de Grafana en GB."
  type        = number
  default     = 20
}

variable "ssh_cidr_blocks" {
  description = "CIDR permitidos para SSH. Por seguridad viene vacío."
  type        = list(string)
  default     = []
}

variable "key_name" {
  description = "Nombre de key pair existente para SSH. Si es null, la instancia queda sin key pair."
  type        = string
  default     = null
}

variable "athena_results_bucket_arn" {
  description = "ARN de bucket para resultados Athena. Si es null, el módulo crea uno."
  type        = string
  default     = null
}
