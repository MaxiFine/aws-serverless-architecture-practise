/*
Input Variables

Defines configurable parameters for the Terraform project. These variables 
provide flexibility for deployment across environments without changing 
the core code.  

Variables:
- region: Primary AWS region where resources will be deployed.  
- project_name: Identifier used for naming and tagging AWS resources.  
- tags: Common tags applied to resources for tracking ownership, 
  environment, and project metadata.  

Purpose:
Centralizes configuration values, improves reusability, and enforces 
consistent tagging and naming conventions across resources.  
*/

variable "aws_region" {
  description = "Primary AWS region for resources"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Name of the project (used for resource naming and tagging)."
  type        = string
  default     = "web-app-serverless"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Project     = "Account Vending"
    ManagedBy   = "Terraform"
    Environment = "Dev"
    Owner       = "AWS Competence Center"
    ArchType    = "Serverless"
  }
}

variable "create_nat_gateway" {
  description = "Whether to create a NAT Gateway for private subnet internet access"
  type        = bool
  default     = true
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "total_private_subnets" {
  description = "Number of private subnets to create (must be at least 2 for high availability)"
  type        = number
  default     = 2
}

# Database Configuration Variables
variable "db_username" {
  description = "Database username"
  type        = string
  default     = "admin"
}

# API Gateway Variables
variable "api_stage_name" {
  description = "API Gateway deployment stage name"
  type        = string
  # default     = "dev"
}

# Cognito Variables
variable "localhost_url" {
  description = "Localhost URL for development (callback URL)"
  type        = string
  default     = "http://localhost:3000"
}



variable "managed_login_version" {
  description = "Cognito managed login version"
  type        = string
  default     = "1"
  validation {
    condition     = contains(["1", "2"], var.managed_login_version)
    error_message = "managed_login_version must be \"1\" or \"2\" to match supported Cognito managed login experience versions."
  }
}


############################
# 🔐 Cognito Configuration
############################
variable "user_pool_settings" {
  description = "Configuration for Cognito user pool, including verification, username attributes, password policy, and schema"
  type = object({
    auto_verified_attributes = list(string)
    username_attributes      = list(string)
    password_policy = object({
      min_length         = number
      require_uppercase  = bool
      require_lowercase  = bool
      require_numbers    = bool
      require_symbols    = bool
      temp_validity_days = number
    })
    user_pool_schema = list(object({
      name                = string
      attribute_data_type = string
      mutable             = bool
      required            = bool
    }))
  })

  default = {
    auto_verified_attributes = ["email"]
    username_attributes      = ["email"]
    password_policy = {
      min_length         = 8
      require_uppercase  = true
      require_lowercase  = true
      require_numbers    = true
      require_symbols    = true
      temp_validity_days = 7
    }
    user_pool_schema = [
      { name = "email", attribute_data_type = "String", mutable = false, required = true },
      { name = "role", attribute_data_type = "String", mutable = false, required = false }
    ]
  }
  
  validation {
    condition     = var.user_pool_settings.password_policy.min_length >= 8 && length(var.user_pool_settings.username_attributes) > 0
    error_message = "user_pool_settings invalid: password minimum length must be >= 8 and username_attributes must include at least one attribute."
  }
}

variable "cognito_client_config" {
  description = "Full configuration for Cognito user pool client. Generate secret should be false for public clients using PKCE."
  type = object({
    generate_secret = bool
    oauth_settings = object({
      allowed_flows                = list(string)
      allowed_scopes               = list(string)
      allowed_flows_user_pool      = bool
      supported_identity_providers = list(string)
      explicit_auth_flows          = list(string)
      callback_urls                = list(string)
      logout_urls                  = list(string)
    })
    token_validity = object({
      refresh_token = number
      access_token  = number
      id_token      = number
      refresh_unit  = string
      access_unit   = string
      id_unit       = string
    })
  })
  default = {
    generate_secret = false
    oauth_settings = {
      allowed_flows                = ["code"]
      allowed_scopes               = ["email", "openid", "aws.cognito.signin.user.admin", "profile"]
      allowed_flows_user_pool      = true
      supported_identity_providers = ["COGNITO"]
      explicit_auth_flows          = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
      callback_urls                = ["http://localhost:4200/oauth2/code", "https://example.com/oauth2/code"]
      logout_urls                  = ["http://localhost:4200/logout", "https://example.com/logout"]
    }
    token_validity = {
      refresh_token = 30
      access_token  = 6
      id_token      = 6
      refresh_unit  = "days"
      access_unit   = "hours"
      id_unit       = "hours"
    }
  }
  
  validation {
    condition = alltrue([
      var.cognito_client_config.generate_secret == false,
      contains(var.cognito_client_config.oauth_settings.allowed_flows, "code"),
      var.cognito_client_config.oauth_settings.allowed_flows_user_pool == true,
      alltrue([for u in var.cognito_client_config.oauth_settings.callback_urls : can(regex("^https?://", u))]),
      alltrue([for u in var.cognito_client_config.oauth_settings.logout_urls   : can(regex("^https?://", u))]),
      contains(["minutes", "hours", "days"], var.cognito_client_config.token_validity.refresh_unit),
      contains(["minutes", "hours", "days"], var.cognito_client_config.token_validity.access_unit),
      contains(["minutes", "hours", "days"], var.cognito_client_config.token_validity.id_unit),
      var.cognito_client_config.token_validity.refresh_token > 0,
      var.cognito_client_config.token_validity.access_token  > 0,
      var.cognito_client_config.token_validity.id_token      > 0
    ])
    error_message = "cognito_client_config invalid: PKCE clients must not generate secrets; allowed_flows must include 'code'; callback/logout URLs must start with http(s); token units must be minutes/hours/days; token durations must be > 0."
  }
}

