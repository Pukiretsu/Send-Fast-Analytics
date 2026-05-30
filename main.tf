data "aws_caller_identity" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

module "datalake_storage" {
  source = "./modules/datalake_storage"

  project_name         = var.project_name
  environment          = var.environment
  name_prefix          = local.name_prefix
  allowed_api_origins  = ["*"]
  allowed_cors_origins = ["*"]
}

module "backend_processing" {
  source = "./modules/backend_processing"

  project_name        = var.project_name
  environment         = var.environment
  lambda_runtime      = var.lambda_runtime
  raw_bucket_name     = module.datalake_storage.raw_bucket_name
  raw_bucket_arn      = module.datalake_storage.raw_bucket_arn
  trusted_bucket_name = module.datalake_storage.trusted_bucket_name
  trusted_bucket_arn  = module.datalake_storage.trusted_bucket_arn
}

resource "aws_s3_bucket_notification" "raw_orders_to_lambda" {
  bucket = module.datalake_storage.raw_bucket_id

  lambda_function {
    lambda_function_arn = module.backend_processing.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "orders/"
    filter_suffix       = ".json"
  }

  depends_on = [
    module.backend_processing
  ]
}

module "api_gateway" {
  source = "./modules/api_gateway_s3"

  project_name    = var.project_name
  environment     = var.environment
  aws_region      = var.aws_region
  raw_bucket_name = module.datalake_storage.raw_bucket_name
  raw_bucket_arn  = module.datalake_storage.raw_bucket_arn
}

module "s3_frontend" {
  source = "./modules/s3_frontend"

  project_name           = var.project_name
  environment            = var.environment
  name_prefix            = local.name_prefix
  raw_bucket_id          = module.datalake_storage.raw_bucket_id
  raw_bucket_arn         = module.datalake_storage.raw_bucket_arn
  raw_bucket_name        = module.datalake_storage.raw_bucket_name
  api_gateway_invoke_url = module.api_gateway.invoke_url
}

module "ec2_grafana" {
  source = "./modules/ec2_grafana"

  project_name = var.project_name
  environment  = var.environment
  name_prefix  = local.name_prefix
  aws_region   = var.aws_region
  account_id   = data.aws_caller_identity.current.account_id

  vpc_cidr                    = var.vpc_cidr
  availability_zones          = var.availability_zones
  allowed_grafana_cidr_blocks = var.allowed_grafana_cidr_blocks

  refined_bucket_name = module.datalake_storage.refined_bucket_name
  refined_bucket_arn  = module.datalake_storage.refined_bucket_arn

  grafana_admin_user     = var.grafana_admin_user
  grafana_admin_password = var.grafana_admin_password
  grafana_instance_type  = var.grafana_instance_type
  grafana_volume_size    = var.grafana_volume_size
  ssh_cidr_blocks        = var.ssh_cidr_blocks
  key_name               = var.key_name

  athena_results_bucket_arn = null
}

