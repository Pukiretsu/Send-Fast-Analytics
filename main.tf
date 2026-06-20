# ---------------------------------------------------------
# 👤 Identidad de la cuenta AWS actual
# ---------------------------------------------------------
data "aws_caller_identity" "current" {}

locals {
  project_name = "sendfast"
  environment  = "dev"

  name_prefix = "${local.project_name}-${local.environment}"

  glue_database_name = "${local.project_name}_analytics_${local.environment}"
  glue_orders_table  = "orders"

  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}

# ---------------------------------------------------------
# 🔐 Módulo Cognito
# ---------------------------------------------------------
module "auth_cognito" {
  source        = "./modules/cognito"
  project_name  = local.project_name
  environment   = local.environment
  cognito_users = var.cognito_users
}

# ---------------------------------------------------------
# 🗄️ Módulo DynamoDB
# ---------------------------------------------------------
module "dynamodb_pedidos" {
  source       = "./modules/dynamodb"
  project_name = local.project_name
  environment  = local.environment
}

# ---------------------------------------------------------
# 🪣 S3: Data Lake Bronce / Ingesta Raw
# ---------------------------------------------------------
module "s3_ingest_raw" {
  source              = "./modules/s3"
  bucket_name         = "sendfast-analytics-data-ingest-raw-${local.environment}"
  environment         = local.environment
  block_public_access = true
}

# ---------------------------------------------------------
# 🪣 S3: Data Lake Plata / Stage Parquet
# ---------------------------------------------------------
module "s3_data_stage" {
  source              = "./modules/s3"
  bucket_name         = "sendfast-analytics-data-stage-${local.environment}"
  environment         = local.environment
  block_public_access = true
}

# ---------------------------------------------------------
# 🪣 S3: Resultados Athena
# ---------------------------------------------------------
module "s3_athena_results" {
  source              = "./modules/s3"
  bucket_name         = "${local.project_name}-athena-results-${local.environment}"
  environment         = local.environment
  block_public_access = true
}

# ---------------------------------------------------------
# 🌐 S3: Web App
# ---------------------------------------------------------
module "s3_webapp" {
  source              = "./modules/s3"
  bucket_name         = "sendfast-analytics-web-app-${local.environment}"
  environment         = local.environment
  block_public_access = true
}


# ---------------------------------------------------------
# 🛡️ AWS WAF para CloudFront
# ---------------------------------------------------------
module "waf_cloudfront" {
  source = "./modules/waf_cloudfront"

  providers = {
    aws = aws.global
  }

  project_name = local.project_name
  environment  = local.environment
}

# ---------------------------------------------------------
# 🌐 CloudFront para Web App
# ---------------------------------------------------------

module "cloudfront_webapp" {
  source = "./modules/cloudfront_web"

  project_name = local.project_name
  environment  = local.environment

  s3_bucket_id                   = module.s3_webapp.bucket_id
  s3_bucket_arn                  = module.s3_webapp.bucket_arn
  s3_bucket_regional_domain_name = module.s3_webapp.bucket_regional_domain_name

  price_class = "PriceClass_100"
  web_acl_id  = module.waf_cloudfront.web_acl_arn
}

# ---------------------------------------------------------
# 🧬 Glue Catalog para Athena
# ---------------------------------------------------------
module "glue_catalog_orders" {
  source = "./modules/glue_catalog"

  database_name        = local.glue_database_name
  database_description = "Glue Catalog para pedidos SendFast"
  table_name           = local.glue_orders_table

  table_location = "s3://${module.s3_data_stage.bucket_id}/orders/parquet/"
}

# ---------------------------------------------------------
# ⚙️ Lambdas
# ---------------------------------------------------------
module "microservicios_lambda" {
  source = "./modules/lambda"

  project_name = local.project_name
  environment  = local.environment
  tags         = local.common_tags

  lambdas = {
    # -----------------------------------------------------
    # Lambda Ingesta
    # -----------------------------------------------------
    ingesta = {
      source_dir  = "${path.module}/src/lambdas/ingesta"
      handler     = "lambda_function.lambda_handler"
      runtime     = "python3.11"
      timeout     = 30
      memory_size = 128

      environment_variables = {
        DYNAMODB_TABLE = module.dynamodb_pedidos.table_name
        S3_RAW_BUCKET  = module.s3_ingest_raw.bucket_id
      }

      create_inline_policy = true

      policy_statements = [
        {
          sid = "DynamoDBWritePermissions"

          actions = [
            "dynamodb:PutItem",
            "dynamodb:UpdateItem"
          ]

          resources = [
            module.dynamodb_pedidos.table_arn
          ]
        },
        {
          sid = "S3RawWritePermissions"

          actions = [
            "s3:PutObject"
          ]

          resources = [
            "${module.s3_ingest_raw.bucket_arn}/*"
          ]
        }
      ]
    }

    # -----------------------------------------------------
    # Lambda ETL
    # -----------------------------------------------------
    etl = {
      source_dir  = "${path.module}/src/lambdas/etl"
      handler     = "lambda_function.lambda_handler"
      runtime     = "python3.11"
      timeout     = 300
      memory_size = 1024

      layers = [
        var.awswrangler_layer_arn
      ]

      environment_variables = {
        RAW_BUCKET       = module.s3_ingest_raw.bucket_id
        STAGE_BUCKET     = module.s3_data_stage.bucket_id
        RAW_PREFIX       = "orders/raw/"
        STAGE_PREFIX     = "orders/parquet/"
        LOOKBACK_MINUTES = "15"
        GLUE_DATABASE    = module.glue_catalog_orders.database_name
        GLUE_TABLE       = module.glue_catalog_orders.table_name
      }

      create_inline_policy = true

      policy_statements = [
        {
          sid = "S3RawReadPermissions"

          actions = [
            "s3:GetObject",
            "s3:ListBucket"
          ]

          resources = [
            module.s3_ingest_raw.bucket_arn,
            "${module.s3_ingest_raw.bucket_arn}/*"
          ]
        },
        {
          sid = "S3StageWritePermissions"

          actions = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:DeleteObject",
            "s3:ListBucket"
          ]

          resources = [
            module.s3_data_stage.bucket_arn,
            "${module.s3_data_stage.bucket_arn}/*"
          ]
        },
        {
          sid = "GlueCatalogPermissions"

          actions = [
            "glue:GetDatabase",
            "glue:GetDatabases",
            "glue:GetTable",
            "glue:GetTables",
            "glue:CreateTable",
            "glue:UpdateTable",
            "glue:GetPartition",
            "glue:GetPartitions",
            "glue:CreatePartition",
            "glue:BatchCreatePartition",
            "glue:UpdatePartition"
          ]

          resources = [
            "*"
          ]
        }
      ]
    }
  }

  depends_on = [
    module.glue_catalog_orders
  ]
}

# ---------------------------------------------------------
# 🛰️ API Gateway HTTP
# ---------------------------------------------------------
module "api_gateway" {
  source = "./modules/api_gateway"

  project_name       = local.project_name
  environment        = local.environment
  user_pool_id       = module.auth_cognito.user_pool_id
  client_id          = module.auth_cognito.client_id
  user_pool_endpoint = module.auth_cognito.user_pool_endpoint

  integration_uri      = module.microservicios_lambda.lambda_invoke_arns["ingesta"]
  lambda_function_name = module.microservicios_lambda.lambda_function_names["ingesta"]
}

# ---------------------------------------------------------
# ⏰ EventBridge para ejecutar Lambda ETL cada 15 minutos
# ---------------------------------------------------------
module "eventbridge" {
  source = "./modules/eventbridge"

  project_name = local.project_name
  environment  = local.environment
  tags         = local.common_tags

  rules = {
    etl_every_15_minutes = {
      description          = "Ejecuta Lambda ETL cada 15 minutos para convertir JSON a Parquet"
      schedule_expression  = "rate(15 minutes)"
      enabled              = true
      target_arn           = module.microservicios_lambda.lambda_function_arns["etl"]
      lambda_function_name = module.microservicios_lambda.lambda_function_names["etl"]

      input = jsonencode({
        process = "orders-etl"
        source  = "eventbridge"
      })
    }
  }
}

# ---------------------------------------------------------
# 🏛️ Athena
# ---------------------------------------------------------
module "athena_analytics" {
  source = "./modules/athena"

  project_name             = local.project_name
  environment              = local.environment
  data_lake_bucket_arn     = module.s3_data_stage.bucket_arn
  athena_results_bucket_id = module.s3_athena_results.bucket_id
}

# ---------------------------------------------------------
# 📊 EC2 Grafana
# ---------------------------------------------------------
module "ec2_grafana" {
  source = "./modules/ec2_grafana"

  project_name = local.project_name
  environment  = local.environment
  name_prefix  = local.name_prefix
  aws_region   = var.aws_region
  account_id   = data.aws_caller_identity.current.account_id

  vpc_cidr                    = var.vpc_cidr
  availability_zones          = var.availability_zones
  allowed_grafana_cidr_blocks = var.allowed_grafana_cidr_blocks

  # Bucket Stage / Refined donde quedan los Parquet para Athena
  refined_bucket_name = module.s3_data_stage.bucket_id
  refined_bucket_arn  = module.s3_data_stage.bucket_arn

  # Bucket existente para resultados de Athena
  create_athena_results_bucket = false
  athena_results_bucket_name   = module.s3_athena_results.bucket_id
  athena_results_bucket_arn    = module.s3_athena_results.bucket_arn

  grafana_admin_secret_arn = var.grafana_admin_secret_arn
  grafana_instance_type    = var.grafana_instance_type
  grafana_volume_size      = var.grafana_volume_size
  glue_database_name       = module.glue_catalog_orders.database_name
  athena_workgroup_name    = module.athena_analytics.workgroup_name

  ssh_cidr_blocks = var.ssh_cidr_blocks
  key_name        = var.key_name
}
