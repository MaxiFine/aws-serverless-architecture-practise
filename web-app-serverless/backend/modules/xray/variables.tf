/**
 * ============================================================================
 * Input variables for the X-Ray tracing module
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

variable "log_retention_days" {
  description = "Number of days to retain X-Ray logs"
  type        = number
  default     = 14
}

variable "enable_detailed_tracing" {
  description = "Enable detailed tracing for API endpoints"
  type        = bool
  default     = false
}

variable "sampling_rate" {
  description = "X-Ray sampling rate (0.0 to 1.0)"
  type        = number
  default     = 0.1
  
  validation {
    condition     = var.sampling_rate >= 0.0 && var.sampling_rate <= 1.0
    error_message = "Sampling rate must be between 0.0 and 1.0."
  }
}
