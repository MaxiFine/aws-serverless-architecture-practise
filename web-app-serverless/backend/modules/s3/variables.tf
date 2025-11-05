variable "region" {
  description = "Primary AWS region for resources"
  type        = string
}

variable "project_name" {
  description = "Name of the project or environment (used for tagging and naming)"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to all resources"
  type        = map(string)
}