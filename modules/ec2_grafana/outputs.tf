output "public_ip" {
  value       = aws_instance.grafana.public_ip
  description = "IP pública de la instancia EC2 con Grafana"
}

output "public_dns" {
  value       = aws_instance.grafana.public_dns
  description = "DNS público de la instancia EC2 con Grafana"
}

output "grafana_url" {
  value       = "http://${aws_instance.grafana.public_ip}:3000"
  description = "URL pública para acceder a Grafana"
}

output "security_group_id" {
  value       = aws_security_group.grafana.id
  description = "ID del Security Group de Grafana"
}

output "vpc_id" {
  value       = aws_vpc.this.id
  description = "ID de la VPC creada para Grafana"
}
