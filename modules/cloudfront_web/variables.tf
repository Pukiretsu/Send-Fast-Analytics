variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente"
  type        = string
}

variable "s3_bucket_id" {
  description = "ID/nombre del bucket S3 web"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN del bucket S3 web"
  type        = string
}

variable "s3_bucket_regional_domain_name" {
  description = "Regional domain name del bucket S3"
  type        = string
}

variable "price_class" {
  description = "Clase de precio CloudFront"
  type        = string
  default     = "PriceClass_100"
}

variable "web_acl_id" {
  description = "ARN del Web ACL de AWS WAF asociado a CloudFront. Usar null para no asociar WAF."
  type        = string
  default     = null
}
