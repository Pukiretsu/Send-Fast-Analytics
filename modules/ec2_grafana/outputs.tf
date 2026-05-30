output "instance_id" {
  description = "ID de la instancia EC2 de Grafana."
  value       = aws_instance.grafana.id
}

output "public_ip" {
  description = "IP pública de Grafana."
  value       = aws_instance.grafana.public_ip
}

output "public_dns" {
  description = "DNS público de Grafana."
  value       = aws_instance.grafana.public_dns
}

output "grafana_url" {
  description = "URL de Grafana."
  value       = "http://${aws_instance.grafana.public_ip}:3000"
}

output "athena_results_bucket_arn" {
  description = "ARN del bucket de resultados Athena."
  value       = local.athena_bucket_arn
}
