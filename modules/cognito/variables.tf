variable "project_name" {
  type        = string
  description = "Nombre del proyecto principal"
}

variable "environment" {
  type        = string
  description = "Entorno de despliegue (prod, dev, etc)"
}

# Un único mapa para contener n cantidad de usuarios
variable "cognito_users" {
  type = map(object({
    username = string
    email    = string
    password = string
  }))
  description = "Mapa de usuarios para inicializar en el User Pool"
  sensitive   = true # Protege las contraseñas del mapa en los logs
}