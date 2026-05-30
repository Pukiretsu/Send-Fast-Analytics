variable "aws_region" {
  description = "Región AWS donde se desplegará la solución."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre base del proyecto usado para nombrar recursos."
  type        = string
  default     = "serverless-datalake"
}

variable "environment" {
  description = "Ambiente de despliegue."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Tags adicionales para los recursos."
  type        = map(string)
  default     = {}
}

variable "lambda_runtime" {
  description = "Runtime de Python para la Lambda."
  type        = string
  default     = "python3.12"
}

variable "grafana_admin_user" {
  description = "Usuario administrador inicial de Grafana."
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "Contraseña administradora inicial de Grafana. Cambiar en producción."
  type        = string
  sensitive   = true
  default     = "ChangeMe12345!"
}

variable "vpc_cidr" {
  description = "CIDR de la VPC básica creada para ECS Fargate."
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zones" {
  description = "Zonas de disponibilidad para subredes públicas y privadas."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "allowed_grafana_cidr_blocks" {
  description = "CIDR permitidos para acceder al ALB público de Grafana por HTTP."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}


variable "grafana_cpu" {
  description = "CPU para tarea Fargate de Grafana."
  type        = number
  default     = 512
}

variable "grafana_memory" {
  description = "Memoria para tarea Fargate de Grafana."
  type        = number
  default     = 1024
}

variable "grafana_desired_count" {
  description = "Número deseado de tareas Grafana."
  type        = number
  default     = 1
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
  description = "CIDR permitidos para SSH a la instancia de Grafana. Por defecto no habilita SSH."
  type        = list(string)
  default     = []
}

variable "key_name" {
  description = "Nombre de key pair existente para SSH. Si es null, no se configura key pair."
  type        = string
  default     = null
}
