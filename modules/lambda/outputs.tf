output "lambda_function_names" {
  description = "Nombres de las Lambdas creadas"
  value = {
    for k, v in aws_lambda_function.this : k => v.function_name
  }
}

output "lambda_function_arns" {
  description = "ARNs de las Lambdas creadas"
  value = {
    for k, v in aws_lambda_function.this : k => v.arn
  }
}

output "lambda_invoke_arns" {
  description = "Invoke ARNs de las Lambdas creadas"
  value = {
    for k, v in aws_lambda_function.this : k => v.invoke_arn
  }
}

output "lambda_role_arns" {
  description = "ARNs de los roles creados por el módulo"
  value = {
    for k, v in aws_iam_role.this : k => v.arn
  }
}