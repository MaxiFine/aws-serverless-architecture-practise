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

variable "finding_publishing_frequency" {
  description = "Frequency of GuardDuty findings publication"
  type        = string
  default     = "FIFTEEN_MINUTES"
  
  validation {
    condition = contains(["FIFTEEN_MINUTES", "ONE_HOUR", "SIX_HOURS"], var.finding_publishing_frequency)
    error_message = "Finding publishing frequency must be FIFTEEN_MINUTES, ONE_HOUR, or SIX_HOURS."
  }
}

variable "enable_s3_protection" {
  description = "Enable S3 protection in GuardDuty"
  type        = bool
  default     = true
}

variable "enable_findings_export" {
  description = "Enable exporting findings to S3 bucket"
  type        = bool
  default     = true
}

variable "enable_sns_notifications" {
  description = "Enable SNS notifications for GuardDuty findings"
  type        = bool
  default     = true
}

variable "guardduty_alerts_email" {
  description = "Email address to receive GuardDuty alerts"
  type        = string
  default     = "maxwell.adomako@amalitech.com"
}

variable "log_retention_days" {
  description = "Number of days to retain GuardDuty logs"
  type        = number
  default     = 30
}

variable "threat_intel_set_location" {
  description = "S3 location of threat intelligence set file (leave empty to disable)"
  type        = string
  default     = ""
}

variable "trusted_ip_set_location" {
  description = "S3 location of trusted IP set file (leave empty to disable)"
  type        = string
  default     = ""
}
