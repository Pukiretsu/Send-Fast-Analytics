# ---------------------------------------------------------
# 🔐 SEGURIDAD Y AUTENTICACIÓN (Cognito)
# ---------------------------------------------------------
output "cognito_user_pool_id" {
  value       = module.auth_cognito.user_pool_id
  description = "ID del User Pool generado para configurar la seguridad en API Gateway"
}

output "cognito_client_id" {
  value       = module.auth_cognito.client_id
  description = "ID del aplicativo cliente para autenticación desde la web o scripts"
}

# ---------------------------------------------------------
# 🛰️ CAPA DE INGESTA (API Gateway & DynamoDB)
# ---------------------------------------------------------
output "api_ingesta_url" {
  value       = "${module.api_gateway.api_endpoint}/ingesta"
  description = "Endpoint exacto para enviar pedidos al API Gateway"
}

output "dynamodb_table_name" {
  value       = module.dynamodb_pedidos.table_name
  description = "Nombre de la tabla transaccional de DynamoDB"
}

# ---------------------------------------------------------
# 🏛️ CAPA ANALÍTICA (S3 & Athena)
# ---------------------------------------------------------
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

# ---------------------------------------------------------
# 🌐 WEB APP
# ---------------------------------------------------------
output "webapp_bucket_name" {
  value       = module.s3_webapp.bucket_id
  description = "Bucket privado donde el pipeline publica el build de la aplicación web"
}

output "cloudfront_webapp_url" {
  value       = module.cloudfront_webapp.https_url
  description = "URL HTTPS de la aplicación web servida por CloudFront"
}

output "cloudfront_distribution_id" {
  value       = module.cloudfront_webapp.distribution_id
  description = "ID de la dist CloudFront para invalidaciones"
}

output "webapp_runtime_config" {
  value = {
    VITE_API_URL      = "${module.api_gateway.api_endpoint}/ingesta"
    VITE_USER_POOL_ID = module.auth_cognito.user_pool_id
    VITE_CLIENT_ID    = module.auth_cognito.client_id
  }

  description = "Variables públicas que el pipeline usa para generar .env.production de Vite"
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
  description = "URL pública para acceder a Grafana cuando allowed_grafana_cidr_blocks permite tráfico"
}


output "waf_cloudfront_web_acl_arn" {
  value       = module.waf_cloudfront.web_acl_arn
  description = "ARN del Web ACL asociado a CloudFront"
}
