# ---------------------------------------------------------
# 🔐 SEGURIDAD Y AUTENTICACIÓN (Cognito)
# ---------------------------------------------------------
output "cognito_user_pool_id" {
  value       = module.auth_cognito.user_pool_id
  description = "ID del User Pool generado para configurar la seguridad en API Gateway"
}

output "cognito_client_id" {
  value       = module.auth_cognito.client_id
  description = "ID del Aplicativo Cliente (Client ID) para la generación del token JWT en tus scripts"
}

# ---------------------------------------------------------
# 🛰️ CAPA DE INGESTA (API Gateway & DynamoDB)
# ---------------------------------------------------------
output "api_ingesta_url" {
  value       = "${module.api_gateway.api_endpoint}/ingesta"
  description = "Endpoint exacto para enviar las ráfagas POST de los JSON simulados"
}

output "dynamodb_table_name" {
  value       = module.dynamodb_pedidos.table_name
  description = "Nombre de la tabla transaccional de DynamoDB para monitoreo"
}

# ---------------------------------------------------------
# 🏛️ CAPA ANALÍTICA (S3 & Athena)
# ---------------------------------------------------------
output "s3_webapp_endpoint" {
  value       = module.s3_webapp.website_endpoint
  description = "URL pública para acceder a tu interfaz estática de Bootstrap"
}

output "athena_workgroup_name" {
  value       = module.athena_analytics.workgroup_name
  description = "Nombre del Workgroup de Athena"
}

output "glue_database_name" {
  value       = module.glue_catalog_orders.database_name
  description = "Nombre de la base de datos Glue Catalog"
}

output "glue_orders_table_name" {
  value       = module.glue_catalog_orders.table_name
  description = "Nombre de la tabla Glue Catalog para pedidos"
}

output "grafana_alb_url" {
  description = "URL pública HTTP de Grafana en EC2."
  value       = module.ec2_grafana.grafana_url
}

# ---------------------------------------------------------
# 📊 GRAFANA
# ---------------------------------------------------------
output "grafana_public_ip" {
  value       = module.ec2_grafana.public_ip
  description = "IP pública de la instancia EC2 con Grafana"
}

output "grafana_public_dns" {
  value       = module.ec2_grafana.public_dns
  description = "DNS público de la instancia EC2 con Grafana"
}

output "grafana_url" {
  value       = module.ec2_grafana.grafana_url
  description = "URL pública para acceder a Grafana"
}