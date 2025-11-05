variable "region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Name of the project/stack"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to resources."
  type        = map(string)
}

variable "user_pool_id" {
  description = "The ID of the Cognito User Pool"
  type        = string
}

variable "user_pool_client_id" {
  description = "The ID of the Cognito User Pool Client"
  type        = string
}

variable "user_pool_client_secret" {
  description = "The secret of the Cognito User Pool Client"
  type        = string
}

variable "user_pool_domain" {
  description = "The domain of the Cognito User Pool"
  type        = string
}

variable "protected_rules" {
  description = "List of protected route rules for Lambda@Edge auth gateway"
  type = list(object({
    prefix  = string
    methods = list(string)
  }))
}

