output "database_name" {
  description = "Nombre de la base de datos Glue"
  value       = aws_glue_catalog_database.this.name
}

output "table_name" {
  description = "Nombre de la tabla Glue"
  value       = aws_glue_catalog_table.this.name
}

output "table_location" {
  description = "Ubicación S3 de la tabla"
  value       = var.table_location
}
