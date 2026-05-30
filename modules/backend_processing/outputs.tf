output "lambda_function_arn" {
  value = aws_lambda_function.process_orders.arn
}

output "lambda_s3_permission_id" {
  value = aws_lambda_permission.allow_s3_raw.id
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.orders.name
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.orders.arn
}
