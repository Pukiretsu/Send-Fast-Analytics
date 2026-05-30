output "raw_bucket_id" {
  description = "ID del bucket Raw."
  value       = aws_s3_bucket.this["raw"].id
}

output "raw_bucket_name" {
  description = "Nombre del bucket Raw."
  value       = aws_s3_bucket.this["raw"].bucket
}

output "raw_bucket_arn" {
  description = "ARN del bucket Raw."
  value       = aws_s3_bucket.this["raw"].arn
}

output "trusted_bucket_id" {
  description = "ID del bucket Trusted."
  value       = aws_s3_bucket.this["trusted"].id
}

output "trusted_bucket_name" {
  description = "Nombre del bucket Trusted."
  value       = aws_s3_bucket.this["trusted"].bucket
}

output "trusted_bucket_arn" {
  description = "ARN del bucket Trusted."
  value       = aws_s3_bucket.this["trusted"].arn
}

output "refined_bucket_id" {
  description = "ID del bucket Refined."
  value       = aws_s3_bucket.this["refined"].id
}

output "refined_bucket_name" {
  description = "Nombre del bucket Refined."
  value       = aws_s3_bucket.this["refined"].bucket
}

output "refined_bucket_arn" {
  description = "ARN del bucket Refined."
  value       = aws_s3_bucket.this["refined"].arn
}
