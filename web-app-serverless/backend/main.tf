


# VPC Module - Creates networking infrastructure
module "vpc" {
  source               = "./modules/vpc"
  aws_region               = var.aws_region
  project_name         = var.project_name
  tags                 = var.tags
  vpc_cidr             = var.vpc_cidr_block
}

# Cognito Module - Creates user authentication
module "cognito" {
  source                 = "./modules/cognito"
  project_name           = var.project_name
  tags                   = var.tags
  user_pool_settings    = var.user_pool_settings
  cognito_client_config = var.cognito_client_config
  managed_login_version = var.managed_login_version
}

# RDS Module - Creates relational database
module "rds" {
  source             = "./modules/rds"
  project_name       = var.project_name
  tags               = var.tags
  private_subnets    = module.vpc.private_subnet_ids
  rds_security_group_id = module.vpc.rds_security_group_id
  db_username        = var.db_username
  proxy_security_group_id = module.vpc.proxy_sg_id
}

# S3 Module - Creates object storage
module "s3" {
  source       = "./modules/s3"
  region       = var.aws_region
  project_name = var.project_name
  tags         = var.tags
}

# Lambda Module - Creates serverless functions
module "lambda" {
  source            = "./modules/lambda"
  project_name      = var.project_name
  tags              = var.tags
  lambda_zip_path   = "${path.module}/modules/lambda/lambda_functions"
  private_subnet_ids   = module.vpc.private_subnet_ids
  security_group_id = module.vpc.lambda_security_group_id
  proxy_endpoint    = module.rds.proxy_endpoint
  db_secret_arn     = module.rds.db_secret_arn
  db_username       = module.rds.db_username
  db_host           = module.rds.db_host
  db_port           = module.rds.db_port
  db_name           = module.rds.db_name
  aws_region        = var.aws_region
  db_resource_id    = module.rds.db_resource_id
  proxy_arn        = module.rds.rds_proxy_arn
}

# API Gateway Module - Creates REST API
module "api_gateway" {
  source                      = "./modules/api-gateway"
  project_name                = var.project_name
  tags                        = var.tags
  stage_name                  = var.api_stage_name
  lambda_function_invoke_arn  = module.lambda.lambda_function_invoke_arn
  lambda_function_name        = module.lambda.lambda_function_name
}

# CloudWatch Module - Creates monitoring and alerting
module "cloudwatch" {
  source                    = "./modules/cloudwatch"
  project_name              = var.project_name
  region                    = var.aws_region
  tags                      = var.tags
  lambda_function_name      = module.lambda.lambda_function_name
  api_gateway_name          = module.api_gateway.api_gateway_id
  rds_instance_identifier   = module.rds.db_instance_identifier
  log_retention_days        = 14
}

# X-Ray Module - Creates distributed tracing
module "xray" {
  source                 = "./modules/xray"
  project_name           = var.project_name
  region                 = var.aws_region
  tags                   = var.tags
  enable_detailed_tracing = false
  log_retention_days     = 14
}

# GuardDuty Module - Creates security monitoring
module "guardduty" {
  source                       = "./modules/guardduty"
  project_name                 = var.project_name
  region                       = var.aws_region
  tags                         = var.tags
  finding_publishing_frequency = "SIX_HOURS"
  log_retention_days          = 30
  guardduty_alerts_email      = "maxwell.adomako@amalitech.com"
  enable_sns_notifications    = true
}
