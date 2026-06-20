output "distribution_id" {
  value       = aws_cloudfront_distribution.this.id
  description = "ID de la distribución CloudFront"
}

output "distribution_arn" {
  value       = aws_cloudfront_distribution.this.arn
  description = "ARN de la distribución CloudFront"
}

output "domain_name" {
  value       = aws_cloudfront_distribution.this.domain_name
  description = "Dominio HTTPS de CloudFront"
}

output "https_url" {
  value       = "https://${aws_cloudfront_distribution.this.domain_name}"
  description = "URL HTTPS de la aplicación web"
}
