variable "bucket_name" {
  type        = string
  description = "Nombre único global para el bucket de S3"
}

variable "environment" {
  type        = string
  description = "Entorno de despliegue (prod, dev, etc.)"
}

# 🔐 Parámetro Opcional: Bloqueo de Acceso Público (Por defecto TRUE / Seguro)
variable "block_public_access" {
  type        = bool
  description = "Si es true, bloquea todo el tráfico público. Setear en false para Web Apps estáticas."
  default     = true
}

# 🌐 Parámetro Opcional: Configuración de Sitio Web Estático (Por defecto nulo/desactivado)
variable "website_config" {
  type = object({
    index_document = string
    error_document = string
  })
  description = "Configuración para hosting de páginas web estáticas. Si no se pasa, no se activa."
  default     = null
}

variable "upload_directory" {
  type        = string
  description = "Ruta local de la carpeta cuyos archivos se subirán al bucket. Dejar en null si no se requiere subir nada."
  default     = null
}