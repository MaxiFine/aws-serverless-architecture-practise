/**
  Root Terraform for the web-ec2-scenario.

  What it provisions:
  - backend (./backend): VPC/subnets, ALB, EC2 app server, RDS, and Cognito User Pool + Client
  - edge (./lambda_edge): Lambda@Edge built in us-east-1 for auth/headers integration with CloudFront
  - frontend (./frontend): S3 + CloudFront distribution, wired to ALB and Lambda@Edge

  Post-provision step:
  - Uses a local-exec to call AWS CLI and update the Cognito User Pool Client
    with CloudFront callback and logout URLs after the distribution is created

  Cross-module wiring:
  - frontend.alb_domain_name comes from backend.alb_dns_name
  - frontend.lambda_edge_arn comes from edge
  - edge Cognito settings come from backend (user_pool_id/client/secret/domain)
  - local-exec references frontend.cloudfront_domain_name and backend Cognito outputs

  Inputs (selected): project_name, region, tags, VPC/subnets, AMI/instance, DB and Cognito settings, app/db ports
*/

module "backend" {
  source = "./backend"

  project_name          = var.project_name
  aws_region                = var.region
  tags                  = var.tags
  user_pool_settings    = var.user_pool_settings
  cognito_client_config = var.cognito_client_config
  managed_login_version = var.managed_login_version
  api_stage_name        = var.api_stage_name
}

module "frontend" {
  source = "./frontend"

  region                 = var.region
  project_name           = var.project_name
  tags                   = var.tags
  cloudfront_price_class = var.cloudfront_price_class
  default_root_object    = var.default_root_object
  cloudfront_alias       = var.cloudfront_alias
  api_gateway_url        = module.backend.api_gateway_stage_domain_name
  lambda_edge_arn        = module.lambda_edge.lambda_edge_arn
  api_stage_name         = var.api_stage_name

}

# Edge module: build Lambda@Edge separately (us-east-1) and feed ARN to frontend
module "lambda_edge" {
  source = "./lambda_edge"
  providers = {
    aws.us_east_1 = aws.us_east_1
  }
  region                  = var.region
  project_name            = var.project_name
  tags                    = var.tags
  user_pool_id            = module.backend.user_pool_id
  user_pool_client_id     = module.backend.user_pool_client_id
  user_pool_client_secret = module.backend.user_pool_client_secret
  user_pool_domain        = module.backend.user_pool_domain
  protected_rules         = var.protected_rules
}

# Post-provision update: add CloudFront callback URL to Cognito using terraform_data with local-exec
resource "terraform_data" "cognito_client_updater" {
  triggers_replace = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-lc"]
    command = "set -euo pipefail && REGION='${var.region}' && USER_POOL_ID='${module.backend.user_pool_id}' && CLIENT_ID='${module.backend.user_pool_client_id}' && aws cognito-idp update-user-pool-client --region \"$REGION\" --cli-input-json '{\"UserPoolId\": \"'\"$USER_POOL_ID\"'\", \"ClientId\": \"'\"$CLIENT_ID\"'\", \"AllowedOAuthFlows\": ${jsonencode(var.cognito_client_config.oauth_settings.allowed_flows)}, \"AllowedOAuthScopes\": ${jsonencode(var.cognito_client_config.oauth_settings.allowed_scopes)}, \"AllowedOAuthFlowsUserPoolClient\": ${tostring(var.cognito_client_config.oauth_settings.allowed_flows_user_pool)}, \"SupportedIdentityProviders\": ${jsonencode(var.cognito_client_config.oauth_settings.supported_identity_providers)}, \"ExplicitAuthFlows\": ${jsonencode(var.cognito_client_config.oauth_settings.explicit_auth_flows)}, \"CallbackURLs\": ${jsonencode(distinct(concat(var.cognito_client_config.oauth_settings.callback_urls, ["https://${module.frontend.cloudfront_domain_name}/callback"])))}, \"LogoutURLs\": ${jsonencode(distinct(concat(var.cognito_client_config.oauth_settings.logout_urls, ["https://${module.frontend.cloudfront_domain_name}/logout"])))}, \"AccessTokenValidity\": ${var.cognito_client_config.token_validity.access_token}, \"IdTokenValidity\": ${var.cognito_client_config.token_validity.id_token}, \"RefreshTokenValidity\": ${var.cognito_client_config.token_validity.refresh_token}, \"TokenValidityUnits\": ${jsonencode({AccessToken = var.cognito_client_config.token_validity.access_unit, IdToken = var.cognito_client_config.token_validity.id_unit, RefreshToken = var.cognito_client_config.token_validity.refresh_unit})}}'"
  }

depends_on = [module.backend, module.frontend]
}


resource "terraform_data" "allowed_origin_data" {
 
  # Use AWS CLI to update API Gateway CORS config
 triggers_replace = {
  cloudfront_url = module.frontend.cloudfront_domain_name
  }
  provisioner "local-exec" {
    command = <<EOT
      echo "Updating API Gateway (${module.backend.api_gateway_id}) allowed origin to: ${module.frontend.cloudfront_domain_name}"

      aws apigatewayv2 update-api --api-id ${module.backend.api_gateway_id} --cors-configuration "AllowOrigins=['${module.frontend.cloudfront_domain_name}']"

      echo "✅ Successfully updated CORS allowed origin to: ${module.frontend.cloudfront_domain_name}"
    EOT
  }
}
