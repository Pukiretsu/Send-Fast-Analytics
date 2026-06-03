variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "data_lake_bucket_arn" {
  type        = string
  description = "ARN del bucket del Data Lake"
}

variable "athena_results_bucket_id" {
  type        = string
  description = "ID/Nombre del bucket de S3 para resultados de Athena"
}