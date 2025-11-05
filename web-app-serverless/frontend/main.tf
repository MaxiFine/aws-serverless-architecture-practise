

/**
  Frontend stack for the web-ec2-scenario.

  What it provisions:
  - module.s3: Static site bucket used as CloudFront origin (and for assets)
  - module.cloudfront: Distribution pointing to S3 and proxying to ALB for app traffic

  Cross-module wiring:
  - cloudfront.s3_origin_id/domain/arn come from module.s3 outputs
  - cloudfront.alb_domain_name is provided by the backend module from root
  - cloudfront.lambda_edge_arn is passed from the edge module (us-east-1)

  Inputs (selected):
  - project_name, region, tags
  - default_root_object, cloudfront_price_class, cloudfront_alias
  - alb_domain_name, lambda_edge_arn
**/

# S3 module
module "s3" {
  source                      = "./modules/s3"
  project_name                = var.project_name
  tags                        = var.tags
  cloudfront_distribution_arn = module.cloudfront.distribution_arn
}

# CloudFront module
module "cloudfront" {
  source                 = "./modules/cloudfront"
  region                 = var.region
  project_name           = var.project_name
  tags                   = var.tags
  s3_origin_id           = module.s3.bucket_id
  s3_bucket_domain       = module.s3.bucket_regional_domain_name
  s3_bucket_arn          = module.s3.bucket_arn
  default_root_object    = var.default_root_object
  cloudfront_price_class = var.cloudfront_price_class
  cloudfront_aliases     = [var.cloudfront_alias]
  api_gateway_url        = var.api_gateway_url
  lambda_edge_arn        = var.lambda_edge_arn
  api_stage_name         = var.api_stage_name
}