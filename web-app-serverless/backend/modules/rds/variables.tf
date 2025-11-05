variable "project_name" {
  description = "Name of the project or environment (used for tagging and naming)"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to all resources"
  type        = map(string)
}

variable "private_subnets" {
  description = "values of the private subnets"
  type        = list(string)
}

variable "rds_security_group_id" {
  description = "value of the security group id"
  type        = string
}

variable "db_username" {
  description = "value of the database username"
  type        = string
}


variable "proxy_security_group_id" {
  description = "Security Group ID for RDS Proxy"
  type        = string
}