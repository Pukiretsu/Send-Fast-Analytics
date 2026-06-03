output "workgroup_name" {
  value       = aws_athena_workgroup.this.name
  description = "Nombre del Workgroup para configurar la conexión en Grafana"
}
