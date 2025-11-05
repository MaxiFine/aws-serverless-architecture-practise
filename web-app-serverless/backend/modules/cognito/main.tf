/**
  Cognito authentication for Serverless Scenario.
  - aws_cognito_user_pool: creates user pool with password policy and optional schema
  - aws_cognito_user_pool_client: configures OAuth flows/scopes, callbacks, token validity
  - aws_cognito_user_pool_domain: provisions a managed Hosted UI domain (per-account suffix)

  Inputs:
  - project_name, tags
  - user_pool_settings: { auto_verified_attributes, username_attributes, password_policy, user_pool_schema[] }
  - cognito_client_config: { generate_secret, oauth_settings{...}, token_validity{...} }
  - managed_login_version

  Notes:
  - Callback/logout URLs may be post-updated by root to include CloudFront domain
  - Generate secret can be toggled depending on public client requirements
*/
data "aws_caller_identity" "current" {}

# 🔐 AWS Cognito User Pool
resource "aws_cognito_user_pool" "user_pool" {
  name                     = "${var.project_name}-user-pool"
  auto_verified_attributes = var.user_pool_settings.auto_verified_attributes
  username_attributes      = var.user_pool_settings.username_attributes

  password_policy {
    minimum_length                   = var.user_pool_settings.password_policy.min_length
    require_uppercase                = var.user_pool_settings.password_policy.require_uppercase
    require_lowercase                = var.user_pool_settings.password_policy.require_lowercase
    require_numbers                  = var.user_pool_settings.password_policy.require_numbers
    require_symbols                  = var.user_pool_settings.password_policy.require_symbols
    temporary_password_validity_days = var.user_pool_settings.password_policy.temp_validity_days
  }

  dynamic "schema" {
    for_each = var.user_pool_settings.user_pool_schema
    content {
      name                = schema.value.name
      attribute_data_type = schema.value.attribute_data_type
      mutable             = schema.value.mutable
      required            = schema.value.required
    }
  }

  lifecycle {
    ignore_changes = [schema]
  }

  tags = merge(
    var.tags,
    { Name = "${var.project_name}-user-pool" }
  )
}

# 👤 AWS Cognito User Pool Client
resource "aws_cognito_user_pool_client" "user_pool_client" {
  name            = "${var.project_name}-user-pool-client"
  user_pool_id    = aws_cognito_user_pool.user_pool.id
  generate_secret = var.cognito_client_config.generate_secret

  allowed_oauth_flows_user_pool_client = var.cognito_client_config.oauth_settings.allowed_flows_user_pool
  allowed_oauth_flows                  = var.cognito_client_config.oauth_settings.allowed_flows
  allowed_oauth_scopes                 = var.cognito_client_config.oauth_settings.allowed_scopes
  supported_identity_providers         = var.cognito_client_config.oauth_settings.supported_identity_providers
  explicit_auth_flows                  = var.cognito_client_config.oauth_settings.explicit_auth_flows
  callback_urls                        = var.cognito_client_config.oauth_settings.callback_urls
  logout_urls                          = var.cognito_client_config.oauth_settings.logout_urls

  refresh_token_validity = var.cognito_client_config.token_validity.refresh_token
  access_token_validity  = var.cognito_client_config.token_validity.access_token
  id_token_validity      = var.cognito_client_config.token_validity.id_token

  token_validity_units {
    refresh_token = var.cognito_client_config.token_validity.refresh_unit
    access_token  = var.cognito_client_config.token_validity.access_unit
    id_token      = var.cognito_client_config.token_validity.id_unit
  }

  depends_on = [aws_cognito_user_pool.user_pool]
}

# 🌐 AWS Cognito Domain
resource "aws_cognito_user_pool_domain" "user_pool_domain" {
  domain                = "${var.project_name}-${data.aws_caller_identity.current.account_id}-domain"
  user_pool_id          = aws_cognito_user_pool.user_pool.id
  managed_login_version = var.managed_login_version
}
