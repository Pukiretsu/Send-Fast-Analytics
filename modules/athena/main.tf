# ---------------------------------------------------------
# ⚙️ Workgroup de Athena
# ---------------------------------------------------------
resource "aws_athena_workgroup" "this" {
  name        = "${var.project_name}-${var.environment}-workgroup"
  description = "Workgroup para las consultas analíticas de Send Fast desde Grafana"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${var.athena_results_bucket_id}/athena-results/"
    }
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
