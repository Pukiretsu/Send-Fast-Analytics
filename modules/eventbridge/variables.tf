variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente"
  type        = string
}

variable "tags" {
  description = "Tags comunes"
  type        = map(string)
  default     = {}
}

variable "rules" {
  description = "Mapa de reglas EventBridge"
  type = map(object({
    description              = optional(string)
    schedule_expression      = string
    enabled                  = optional(bool, true)
    target_id                = optional(string)
    target_arn               = string
    lambda_function_name     = string
    create_lambda_permission = optional(bool, true)
    input                    = optional(string)
  }))
}
