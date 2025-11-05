variable "project_name" {
  description = "Name of the project/stack"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to resources."
  type        = map(string)
}

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
}

variable "cognito_client_config" {
  description = "Full configuration for Cognito user pool client"
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
}

variable "managed_login_version" {
  description = "Cognito managed login version"
  type        = string
}