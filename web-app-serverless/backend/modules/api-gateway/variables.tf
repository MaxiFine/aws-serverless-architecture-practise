/**
 * ============================================================================
 * API Gateway Module Variables
 * ============================================================================
 * Input variables for the API Gateway module configuration.
 * ============================================================================
 */

variable "project_name" {
  description = "Name of the project (used for resource naming and tagging)"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
}

variable "stage_name" {
  description = "API Gateway deployment stage name"
  type        = string
}



variable "lambda_function_invoke_arn" {
  description = "Lambda function invoke ARN for API Gateway integration"
  type        = string
}

variable "lambda_function_name" {
  description = "Lambda function name for API Gateway permissions"
  type        = string
}



