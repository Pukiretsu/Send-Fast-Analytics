resource "aws_cognito_user_pool" "this" {
  name = "${var.project_name}-${var.environment}-user-pool"

  # Password Policies para la contraseña en cognito
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  username_attributes = []

  auto_verified_attributes = ["email"]

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
  }

  tags = {
    name        = "${var.project_name}-${var.environment}-user-pool"
    environment = var.environment
  }
}

resource "aws_cognito_user_pool_client" "this" {
  name            = "${var.project_name}-${var.environment}-client-app"
  user_pool_id    = aws_cognito_user_pool.this.id
  generate_secret = false

  # Flujos de autenticación permitidos
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH", # Requerido para USER_PASSWORD_AUTH en boto3
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  supported_identity_providers = ["COGNITO"]
}

resource "aws_cognito_user" "this" {
  for_each = nonsensitive(var.cognito_users)

  user_pool_id = aws_cognito_user_pool.this.id
  username     = each.value.username

  attributes = {
    email          = each.value.email
    email_verified = "true"
  }

  password                 = each.value.password
  desired_delivery_mediums = ["EMAIL"]
}
