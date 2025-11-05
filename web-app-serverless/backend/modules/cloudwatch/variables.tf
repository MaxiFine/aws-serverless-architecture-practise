/**
 * ============================================================================
 * Input variables for the CloudWatch monitoring module
 * ============================================================================
 */

variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
}

variable "region" {
  description = "AWS region for resources"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "lambda_function_name" {
  description = "Name of the Lambda function to monitor"
  type        = string
}

variable "api_gateway_name" {
  description = "Name of the API Gateway to monitor"
  type        = string
}

variable "rds_instance_identifier" {
  description = "RDS instance identifier to monitor"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 14
}

variable "sns_email_endpoint" {
  description = "Email address for SNS notifications (optional)"
  type        = string
  default     = ""
}