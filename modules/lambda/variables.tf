variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente del despliegue"
  type        = string
}

variable "tags" {
  description = "Tags comunes"
  type        = map(string)
  default     = {}
}

variable "lambdas" {
  description = "Mapa de Lambdas a crear"
  type = map(object({
    source_dir  = string
    handler     = optional(string, "lambda_function.lambda_handler")
    runtime     = optional(string, "python3.11")
    timeout     = optional(number, 30)
    memory_size = optional(number, 128)
    layers      = optional(list(string), [])

    create_role          = optional(bool, true)
    role_arn             = optional(string)
    create_inline_policy = optional(bool, false)

    environment_variables = optional(map(string), {})

    managed_policy_arns = optional(list(string), [])

    policy_statements = optional(list(object({
      sid       = optional(string)
      effect    = optional(string, "Allow")
      actions   = list(string)
      resources = list(string)
    })), [])

    event_source_mappings = optional(map(object({
      event_source_arn  = string
      starting_position = optional(string, "LATEST")
      batch_size        = optional(number, 10)
      enabled           = optional(bool, true)
    })), {})

    permissions = optional(map(object({
      statement_id = optional(string)
      action       = optional(string, "lambda:InvokeFunction")
      principal    = string
      source_arn   = optional(string)
    })), {})
  }))
}
