resource "aws_dynamodb_table" "orders_table" {
  name         = "${var.project_name}-${var.environment}-orders"
  billing_mode = "PAY_PER_REQUEST" # 👈 Clave para que el costo sea $0 si está inactivo

  # Llave primaria del pedido (Obligatoria)
  hash_key = "orderId"

  attribute {
    name = "orderId"
    type = "S" # String
  }

  # 🔥 REQUISITO CRUCIAL: Activamos el Stream para que la Lambda ETL pueda leer los cambios
  stream_enabled   = true
  stream_view_type = "NEW_IMAGE" # Envía el objeto completo tal como quedó después de crearse

  tags = {
    Name        = "${var.project_name}-${var.environment}-orders"
    Environment = var.environment
  }
}
