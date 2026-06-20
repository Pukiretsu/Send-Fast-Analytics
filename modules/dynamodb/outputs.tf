output "table_name" {
  value = aws_dynamodb_table.orders_table.name
}

output "table_arn" {
  value = aws_dynamodb_table.orders_table.arn
}

output "stream_arn" {
  value = aws_dynamodb_table.orders_table.stream_arn
}
