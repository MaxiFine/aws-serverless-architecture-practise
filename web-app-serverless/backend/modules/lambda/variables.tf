variable "project_name" {
  description = "Name of the project or environment (used for tagging and naming)"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to all resources"
  type        = map(string)
}

variable "lambda_zip_path" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "security_group_id" { type = string }
variable "proxy_endpoint" { type = string }
variable "db_secret_arn" { type = string }


variable "db_username" {
  description = "value of the database username"
  type        = string
}

variable "db_host" {
  description = "value of the database host"
  type        = string
}

variable "db_port" {
  description = "value of the database port"
  type        = string
}

variable "db_name" {
  description = "value of the database name"
  type        = string
}

variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
}


variable "db_resource_id" {
  description = "RDS database resource-id (dbi-...) for IAM rds-db:connect"
  type        = string
}

variable "proxy_arn" {
  description = "RDS Proxy ARN"
  type        = string
}