output "cloudfront_url" {
  description = "URL pública HTTPS del frontend estático."
  value       = "https://${module.s3_frontend.cloudfront_domain_name}"
}

output "api_gateway_orders_url" {
  description = "Endpoint POST /orders para ingesta de órdenes."
  value       = "${module.api_gateway.invoke_url}/orders"
}

output "grafana_alb_url" {
  description = "URL pública HTTP de Grafana en EC2."
  value       = module.ec2_grafana.grafana_url
}

output "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB de órdenes."
  value       = module.backend_processing.dynamodb_table_name
}

output "raw_bucket_name" {
  description = "Bucket Raw del Data Lake."
  value       = module.datalake_storage.raw_bucket_name
}

output "trusted_bucket_name" {
  description = "Bucket Trusted del Data Lake."
  value       = module.datalake_storage.trusted_bucket_name
}

output "refined_bucket_name" {
  description = "Bucket Refined del Data Lake."
  value       = module.datalake_storage.refined_bucket_name
}
