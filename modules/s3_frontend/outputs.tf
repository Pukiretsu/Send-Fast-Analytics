output "bucket_name" {
  description = "Nombre del bucket frontend."
  value       = aws_s3_bucket.frontend.bucket
}

output "cloudfront_domain_name" {
  description = "Dominio CloudFront."
  value       = aws_cloudfront_distribution.frontend.domain_name
}
