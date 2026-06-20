variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente"
  type        = string
}

variable "rate_limit" {
  description = "Cantidad máxima de requests por IP en una ventana de 5 minutos"
  type        = number
  default     = 2000
}
