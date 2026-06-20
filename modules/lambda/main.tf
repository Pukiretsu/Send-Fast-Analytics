# ---------------------------------------------------------
# 📦 ZIP automático por cada Lambda
# ---------------------------------------------------------
data "archive_file" "lambda_zip" {
  for_each = var.lambdas

  type        = "zip"
  source_dir  = each.value.source_dir
  output_path = "${path.root}/.terraform/${each.key}.zip"
}

# ---------------------------------------------------------
# 🛡️ Assume Role Policy para Lambda
# ---------------------------------------------------------
data "aws_iam_policy_document" "lambda_assume_role" {
  for_each = {
    for k, v in var.lambdas : k => v
    if try(v.create_role, true)
  }

  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
  }
}

# ---------------------------------------------------------
# 🛡️ IAM Role por Lambda
# ---------------------------------------------------------
resource "aws_iam_role" "this" {
  for_each = {
    for k, v in var.lambdas : k => v
    if try(v.create_role, true)
  }

  name = "${var.project_name}-${var.environment}-${each.key}-lambda-role"

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role[each.key].json

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-${each.key}-lambda-role"
    Environment = var.environment
  })
}

# ---------------------------------------------------------
# 📌 Política básica de logs para cada Lambda
# ---------------------------------------------------------
resource "aws_iam_role_policy_attachment" "basic_execution" {
  for_each = aws_iam_role.this

  role       = each.value.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ---------------------------------------------------------
# 📌 Adjuntar políticas administradas adicionales
# ---------------------------------------------------------
locals {
  managed_policy_attachments = flatten([
    for lambda_key, lambda_config in var.lambdas : [
      for policy_arn in try(lambda_config.managed_policy_arns, []) : {
        key        = "${lambda_key}-${replace(policy_arn, ":", "-")}"
        lambda_key = lambda_key
        policy_arn = policy_arn
      }
      if try(lambda_config.create_role, true)
    ]
  ])
}

resource "aws_iam_role_policy_attachment" "managed_policies" {
  for_each = {
    for item in local.managed_policy_attachments : item.key => item
  }

  role       = aws_iam_role.this[each.value.lambda_key].name
  policy_arn = each.value.policy_arn
}

# ---------------------------------------------------------
# 🛡️ Políticas inline personalizadas por Lambda
# ---------------------------------------------------------
data "aws_iam_policy_document" "inline_policy" {
  for_each = {
    for k, v in var.lambdas : k => v
    if try(v.create_role, true)
  }

  dynamic "statement" {
    for_each = try(each.value.policy_statements, [])

    content {
      sid       = try(statement.value.sid, null)
      effect    = try(statement.value.effect, "Allow")
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}

resource "aws_iam_policy" "inline_policy" {
  for_each = {
    for k, v in var.lambdas : k => v
    if try(v.create_role, true)
  }

  name        = "${var.project_name}-${var.environment}-${each.key}-lambda-policy"
  description = "Custom policy for ${each.key} Lambda"
  policy      = data.aws_iam_policy_document.inline_policy[each.key].json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "inline_policy_attachment" {
  for_each = aws_iam_policy.inline_policy

  role       = aws_iam_role.this[each.key].name
  policy_arn = each.value.arn
}

# ---------------------------------------------------------
# 🚀 Lambdas
# ---------------------------------------------------------
resource "aws_lambda_function" "this" {
  for_each = var.lambdas

  filename      = data.archive_file.lambda_zip[each.key].output_path
  function_name = "${var.project_name}-${var.environment}-${each.key}"
  role          = try(each.value.role_arn, null) != null ? each.value.role_arn : aws_iam_role.this[each.key].arn
  handler       = try(each.value.handler, "lambda_function.lambda_handler")
  runtime       = try(each.value.runtime, "python3.11")
  timeout       = try(each.value.timeout, 30)
  memory_size   = try(each.value.memory_size, 128)
  layers        = try(each.value.layers, [])

  source_code_hash = data.archive_file.lambda_zip[each.key].output_base64sha256

  dynamic "environment" {
    for_each = length(try(each.value.environment_variables, {})) > 0 ? [1] : []

    content {
      variables = each.value.environment_variables
    }
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-${each.key}"
    Environment = var.environment
  })
}

# ---------------------------------------------------------
# ⚡ Event Source Mappings
# Para DynamoDB Streams, SQS, Kinesis, etc.
# ---------------------------------------------------------
locals {
  event_source_mappings = flatten([
    for lambda_key, lambda_config in var.lambdas : [
      for mapping_key, mapping in try(lambda_config.event_source_mappings, {}) : {
        key        = "${lambda_key}-${mapping_key}"
        lambda_key = lambda_key
        mapping    = mapping
      }
    ]
  ])
}

resource "aws_lambda_event_source_mapping" "this" {
  for_each = {
    for item in local.event_source_mappings : item.key => item
  }

  event_source_arn  = each.value.mapping.event_source_arn
  function_name     = aws_lambda_function.this[each.value.lambda_key].arn
  starting_position = try(each.value.mapping.starting_position, "LATEST")
  batch_size        = try(each.value.mapping.batch_size, 10)
  enabled           = try(each.value.mapping.enabled, true)
}

# ---------------------------------------------------------
# 🔐 Permisos de invocación
# Para API Gateway, S3, EventBridge, SNS, etc.
# ---------------------------------------------------------
locals {
  lambda_permissions = flatten([
    for lambda_key, lambda_config in var.lambdas : [
      for permission_key, permission in try(lambda_config.permissions, {}) : {
        key            = "${lambda_key}-${permission_key}"
        lambda_key     = lambda_key
        permission_key = permission_key
        permission     = permission
      }
    ]
  ])
}

resource "aws_lambda_permission" "this" {
  for_each = {
    for item in local.lambda_permissions : item.key => item
  }

  statement_id  = try(each.value.permission.statement_id, "Allow${each.value.permission_key}Invoke")
  action        = try(each.value.permission.action, "lambda:InvokeFunction")
  function_name = aws_lambda_function.this[each.value.lambda_key].function_name
  principal     = each.value.permission.principal
  source_arn    = try(each.value.permission.source_arn, null)
}
