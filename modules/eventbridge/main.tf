# ---------------------------------------------------------
# ⏰ Reglas dinámicas de EventBridge
# ---------------------------------------------------------
resource "aws_cloudwatch_event_rule" "this" {
  for_each = var.rules

  name                = "${var.project_name}-${var.environment}-${each.key}"
  description         = try(each.value.description, null)
  schedule_expression = each.value.schedule_expression
  state               = try(each.value.enabled, true) ? "ENABLED" : "DISABLED"

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-${each.key}"
    Environment = var.environment
  })
}

# ---------------------------------------------------------
# 🎯 Targets dinámicos
# ---------------------------------------------------------
resource "aws_cloudwatch_event_target" "this" {
  for_each = var.rules

  rule      = aws_cloudwatch_event_rule.this[each.key].name
  target_id = try(each.value.target_id, "${each.key}-target")
  arn       = each.value.target_arn

  input = try(each.value.input, null)
}

# ---------------------------------------------------------
# 🔐 Permiso para que EventBridge invoque Lambda
# ---------------------------------------------------------
resource "aws_lambda_permission" "allow_eventbridge" {
  for_each = {
    for k, v in var.rules : k => v
    if try(v.create_lambda_permission, true)
  }

  statement_id  = "AllowExecutionFromEventBridge-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.this[each.key].arn
}
