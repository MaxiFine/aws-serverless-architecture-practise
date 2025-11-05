# # Simplified Variables for VPC Networking Deployment
# # Direct resource count specification - no complex logic required

# Basic Configuration
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "project_name" {
  description = "Name of the project or environment (used for tagging and naming)"
  type        = string
}

variable "db_port" {
  description = "Databse Port Number"
  type = string
  default = "3306"
}


variable "database_route_tables_total" {
  description = "Total number of database route tables to create (0 = none)"
  type        = number
  default     = 0
}



#####################
## VPC NETWORKING VARIABLES
#####################
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Direct Resource Count Variables - No Complex Logic
variable "az_count" {
  description = "Number of Availability Zones to use (1-3)"
  type        = number
  default     = 2
  validation {
    condition     = var.az_count >= 1 && var.az_count <= 3
    error_message = "AZ count must be between 1 and 3."
  }
}

variable "public_subnets_total" {
  description = "Total number of public subnets to create"
  type        = number
  default     = 2
}

variable "private_subnets_total" {
  description = "Total number of private subnets to create"
  type        = number
  default     = 2
}

variable "database_subnets_total" {
  description = "Total number of database subnets to create (0 = none)"
  type        = number
  default     = 0
}

variable "nat_gateways_total" {
  description = "Total number of NAT Gateways to create (0 = none)"
  type        = number
  default     = 1
}

variable "public_route_tables_total" {
  description = "Total number of public route tables to create"
  type        = number
  default     = 1
}

variable "private_route_tables_total" {
  description = "Total number of private route tables to create"
  type        = number
  default     = 1
}


variable "tags" {
  description = "A map of tags to assign to resources."
  type        = map(string)
}