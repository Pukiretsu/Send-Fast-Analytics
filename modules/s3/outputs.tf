output "bucket_id" {
  value       = aws_s3_bucket.this.id
  description = "El nombre/ID del bucket creado"
}

output "bucket_arn" {
  value       = aws_s3_bucket.this.arn
  description = "El ARN del bucket, ideal para políticas IAM"
}

output "website_endpoint" {
  value       = length(aws_s3_bucket_website_configuration.this) > 0 ? aws_s3_bucket_website_configuration.this[0].website_endpoint : null
  description = "URL pública del sitio web estático (si está activo)"
}