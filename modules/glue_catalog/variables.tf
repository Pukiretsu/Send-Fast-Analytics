variable "database_name" {
  description = "Nombre de la base de datos Glue"
  type        = string
}

variable "database_description" {
  description = "Descripción de la base de datos Glue"
  type        = string
  default     = "Glue database for analytics"
}

variable "table_name" {
  description = "Nombre de la tabla Glue"
  type        = string
}

variable "table_location" {
  description = "Ubicación S3 donde están los archivos Parquet"
  type        = string
}
