data "aws_caller_identity" "current" {}

locals {
  bucket_suffix = data.aws_caller_identity.current.account_id
  prefix        = var.name_prefix != null ? var.name_prefix : "${var.project_name}-${var.environment}"

  buckets = {
    raw     = "${local.prefix}-s3-datalake-raw-${local.bucket_suffix}"
    trusted = "${local.prefix}-s3-datalake-trusted-${local.bucket_suffix}"
    refined = "${local.prefix}-s3-datalake-refined-${local.bucket_suffix}"
  }
}

resource "aws_s3_bucket" "this" {
  for_each = local.buckets

  bucket        = each.value
  force_destroy = false
}

resource "aws_s3_bucket_public_access_block" "this" {
  for_each = aws_s3_bucket.this

  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  for_each = aws_s3_bucket.this

  bucket = each.value.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  for_each = aws_s3_bucket.this

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "raw" {
  bucket = aws_s3_bucket.this["raw"].id

  cors_rule {
    allowed_headers = ["Content-Type", "Authorization", "X-Amz-Date", "X-Api-Key", "X-Amz-Security-Token"]
    allowed_methods = ["POST", "PUT", "GET"]
    allowed_origins = length(var.allowed_cors_origins) > 0 ? var.allowed_cors_origins : ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}
