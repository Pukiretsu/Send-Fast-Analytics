output "rule_names" {
  description = "Nombres de reglas EventBridge"
  value = {
    for k, v in aws_cloudwatch_event_rule.this : k => v.name
  }
}

output "rule_arns" {
  description = "ARNs de reglas EventBridge"
  value = {
    for k, v in aws_cloudwatch_event_rule.this : k => v.arn
  }
}