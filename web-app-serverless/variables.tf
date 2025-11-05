/*
-------------------------------------------------------------------------------
 Variables for Web EC2 Scenario (root module)
-------------------------------------------------------------------------------
Purpose
- Centralized input definitions for provisioning the backend (VPC, API Gateway, RDS, IAM, Lambda xray, cloudwatch, sns),
  frontend (S3 + CloudFront with OAC), and Lambda@Edge authentication components.

How to set values
- Preferred: define overrides in terraform.tfvars (kept out of VCS) or pass with
  -var/-var-file. Defaults here are safe for development and examples.

Regional considerations
- region defaults to eu-west-1 for regional resources.
- Lambda@Edge functions must be created in us-east-1; the module providers handle this.

Notable variables
- db_settings: production changes (engine version, instance class, Multi-AZ) can trigger
  replacements or brief downtime. Review apply plan carefully.
- cloudfront_alias: replace the example domain if using a custom certificate/alias; leave
  as-is if using the default CloudFront certificate and domain.
- cognito_client_config: generate_secret should remain false for PKCE public clients. When set to true, 
  the client secret must be securely stored and used in authentication flows.
- user_pool_settings: customize password policies and schema attributes as needed.
- ami_id: optional; validated format if provided.

Security & hygiene
- Do not hardcode secrets in tfvars or this file. Prefer AWS SSM Parameter Store/Secrets
  Manager and reference from modules when needed.

Change impact
- Networking CIDR changes, subnet lists, or RDS identifier changes typically force new
  resources. Expect recreation when altering foundational settings.
-------------------------------------------------------------------------------
*/

############################
# 🌍 General Configuration
############################
variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-west-1"
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d$", var.region))
    error_message = "region must be a valid AWS region identifier (e.g., eu-west-1)."
  }
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "web-serverless"

  validation {
    condition = (
      can(regex("^[A-Za-z0-9-]+$", var.project_name)) &&
      length(var.project_name) >= 3 &&
      length(var.project_name) <= 15
    )
    error_message = "project_name must be 3–15 characters long and contain only letters, numbers, and hyphens."
  }
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default = {
    Environment = "Development"
    Project     = "Web-App-Serverless"
    ManagedBy   = "Terraform"

  }
}

############################
# 🏗️ Network Configuration
############################
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block (e.g., 10.0.0.0/16)."
  }
}


variable "private_subnets" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  validation {
    condition     = length(var.private_subnets) > 0 && alltrue([for s in var.private_subnets : can(cidrnetmask(s))])
    error_message = "private_subnets must be a non-empty list of valid IPv4 CIDR blocks."
  }
}


############################
# 🗄️ Database Configuration
############################
variable "db_settings" {
  description = "Database configuration settings for RDS instance"
  type = object({
    username            = string
    name                = string
    engine              = string
    engine_version      = string
    instance_class      = string
    storage_type        = string
    allocated_storage   = number
    identifier_name     = string
    multi_az_deployment = bool
  })

  default = {
    username            = "postgres"
    name                = "web_scenario_db"
    engine              = "postgres"
    engine_version      = "15.8"
    instance_class      = "db.t3.micro"
    storage_type        = "gp2"
    allocated_storage   = 20
    identifier_name     = "serverless-scenario-db-instance"
    multi_az_deployment = true
  }
  
  validation {
    condition = alltrue([
      contains(["postgres", "mysql", "mariadb"], var.db_settings.engine),
      var.db_settings.allocated_storage >= 20,
      contains(["gp2", "gp3", "io1", "io2"], var.db_settings.storage_type),
      can(regex("^db\\.[a-z0-9]+\\.[a-z0-9]+$", var.db_settings.instance_class))
    ])
    error_message = "db_settings invalid: engine must be postgres/mysql/mariadb; allocated_storage >= 20; storage_type one of gp2/gp3/io1/io2; instance_class like db.t3.micro."
  }
}

############################
# 🔌 Application & DB Ports
############################
variable "app_port" {
  description = "Port the application runs on (e.g., 80, 443, or 8080)"
  type        = number
  default     = 8080
  validation {
    condition     = var.app_port >= 1 && var.app_port <= 65535
    error_message = "app_port must be an integer between 1 and 65535."
  }
}

variable "db_port" {
  description = "Database port number (e.g., 5432 for PostgreSQL, 3306 for MySQL)"
  type        = number
  default     = 5432
  validation {
    condition     = var.db_port >= 1 && var.db_port <= 65535
    error_message = "db_port must be an integer between 1 and 65535."
  }
}

variable "api_gateway_health_check_path" {
  description = "Path used by the API Gateway to perform health checks on target instances"
  type        = string
  default     = "/api/health"
  validation {
    condition     = startswith(var.api_gateway_health_check_path, "/")
    error_message = "api_gateway_health_check_path must start with a '/'."
  }
}

############################
# 🌐 CloudFront Configuration
############################
variable "cloudfront_price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.cloudfront_price_class)
    error_message = "cloudfront_price_class must be one of PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

variable "default_root_object" {
  description = "Default root object for CloudFront"
  type        = string
  default     = "index.html"
  validation {
    condition     = var.default_root_object != "" && !startswith(var.default_root_object, "/")
    error_message = "default_root_object must be a non-empty object name (e.g., index.html) without a leading slash."
  }
}

variable "cloudfront_alias" {
  description = "CNAME alias for CloudFront"
  type        = string
  default     = "cdn.example.com"
  validation {
    condition     = var.cloudfront_alias == "" || can(regex("^([A-Za-z0-9-]+\\.)+[A-Za-z]{2,}$", var.cloudfront_alias))
    error_message = "cloudfront_alias must be a valid DNS name (e.g., cdn.example.com) or empty."
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
# 🔒 Auth Protected Routes
############################
variable "protected_rules" {
  description = "Protected route rules for the Lambda@Edge auth gateway. No JS fallback exists—ONLY routes listed here are protected. Each rule requires: prefix (string) and methods (list(string)). Matching is segment-aware: a non-wildcard prefix matches the exact path or that path followed by a '/'. Example: '/app' matches '/app' and '/app/...', not '/app2'. Use '/*' to protect everything and '/path/*' to protect a subtree. When methods is empty, ALL methods are protected for a matched prefix. Any route not matched by these rules is open by default."

  type = list(object({
    prefix  = string
    methods = list(string)
  }))
  default = [
    {
      prefix  = "/api/items"
      methods = ["POST"]
    },
    {
      prefix  = "/items.html"
      methods = []
    }
  ]
}

variable "api_stage_name" {
  description = "API Gateway deployment stage name"
  type        = string
  default     = "dev"

    validation {
    condition = can(regex("^[a-zA-Z0-9-_]{1,10}$", var.api_stage_name))
    error_message = "api_stage_name must be 1–10 characters long and contain only letters, numbers, hyphens, and underscores."
  }
}

