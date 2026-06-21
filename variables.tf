# ---------------------------------------------------------
# 🌍 Configuración Global de AWS
# ---------------------------------------------------------
variable "aws_region" {
  type        = string
  description = "Región de AWS donde se desplegarán los recursos. Para esta arquitectura se recomienda us-east-2."
  default     = "us-east-2"
}

# ---------------------------------------------------------
# 🔐 Usuarios Cognito
# ---------------------------------------------------------
variable "cognito_users" {
  type = map(object({
    username = string
    email    = string
    password = string
  }))

  description = "Mapa de usuarios iniciales de Cognito. Inyectar solo desde secretos del pipeline o tfvars local excluido del repositorio."
  sensitive   = true
}

# ---------------------------------------------------------
# 🧩 Layer oficial AWS SDK for pandas / awswrangler
# ---------------------------------------------------------
variable "awswrangler_layer_arn" {
  description = "ARN del layer oficial AWS SDK for pandas / awswrangler compatible con Python 3.11"
  type        = string
  default     = "arn:aws:lambda:us-east-2:336392948345:layer:AWSSDKPandas-Python311:31"
}

# ---------------------------------------------------------
# 📊 Grafana EC2
# ---------------------------------------------------------
variable "grafana_admin_secret_arn" {
  description = "ARN de AWS Secrets Manager con JSON {\"username\":\"...\",\"password\":\"...\"} para el primer usuario administrador de Grafana."
  type        = string
}

variable "grafana_instance_type" {
  description = "Tipo de instancia EC2 para Grafana"
  type        = string
  default     = "t3.micro"
}

variable "grafana_volume_size" {
  description = "Tamaño del volumen raíz de Grafana en GB"
  type        = number
  default     = 20
}

variable "vpc_cidr" {
  description = "CIDR de la VPC creada para la instancia EC2 de Grafana"
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zones" {
  description = "Zonas de disponibilidad para las subredes públicas de Grafana"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]
}

variable "allowed_grafana_cidr_blocks" {
  description = "CIDR permitidos para acceder a Grafana por el puerto 3000. Por seguridad el valor por defecto no expone Grafana públicamente."
  type        = list(string)
  default     = []
}

variable "ssh_cidr_blocks" {
  description = "CIDR permitidos para SSH a la instancia de Grafana. Por defecto no habilita SSH."
  type        = list(string)
  default     = []
}

variable "key_name" {
  description = "Nombre de Key Pair existente para SSH. Si es null, no se configura key pair."
  type        = string
  default     = null
}
