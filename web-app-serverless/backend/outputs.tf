/**
 * ============================================================================
 * Main Module Outputs
 * ============================================================================
 * Output values from all modules for external use and debugging.
 * ============================================================================
 */

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

# Cognito Outputs
output "cognito_user_pool_id" {
  description = "ID of the Cognito User Pool"
  value       = module.cognito.user_pool_id
}

output "cognito_user_pool_client_id" {
  description = "ID of the Cognito User Pool Client"
  value       = module.cognito.user_pool_client_id
}

output "user_pool_id" {
  description = "ID of the Cognito User Pool"
  value       = module.cognito.user_pool_id
}

output "user_pool_client_id" {
  description = "ID of the Cognito User Pool Client"
  value       = module.cognito.user_pool_client_id
}

output "user_pool_client_secret" {
  description = "Secret of the Cognito User Pool Client"
  value       = module.cognito.user_pool_client_secret
  sensitive   = true
}

output "user_pool_domain" {
  description = "Domain of the Cognito User Pool"
  value       = module.cognito.user_pool_domain
}

# RDS Outputs
output "rds_endpoint" {
  description = "RDS database endpoint"
  value       = module.rds.db_endpoint
}

output "rds_proxy_endpoint" {
  description = "RDS Proxy endpoint"
  value       = module.rds.proxy_endpoint
}

# S3 Outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.s3.bucket_name
}

# Lambda Outputs
output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda.lambda_function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda.lambda_function_arn
}

# API Gateway Outputs
output "api_gateway_invoke_url" {
  description = "API Gateway invoke URL"
  value       = module.api_gateway.api_gateway_invoke_url
}

output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = module.api_gateway.api_gateway_id
}

# For compatibility with frontend module expecting ALB DNS name
output "api_gateway_url" {
  description = "API Gateway URL (replaces ALB DNS name in serverless architecture)"
  value       = module.api_gateway.api_gateway_invoke_url
}

output "api_gateway_stage_domain_name" {
  description = "API Gateway Stage Domain Name"
  value       = module.api_gateway.api_gateway_domain_stage_name
}

# CloudWatch Outputs
output "cloudwatch_dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = module.cloudwatch.dashboard_url
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = module.cloudwatch.sns_topic_arn
}

# X-Ray Outputs
output "xray_service_map_url" {
  description = "URL to the X-Ray service map"
  value       = module.xray.xray_service_map_url
}

output "xray_traces_url" {
  description = "URL to the X-Ray traces console"
  value       = module.xray.xray_traces_url
}

# GuardDuty Outputs
output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector"
  value       = module.guardduty.guardduty_detector_id
}

output "guardduty_console_url" {
  description = "URL to the GuardDuty console"
  value       = module.guardduty.guardduty_console_url
}

# Deployment Summary
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    vpc_id                    = module.vpc.vpc_id
    api_gateway_url           = module.api_gateway.api_gateway_invoke_url
    cognito_user_pool_id      = module.cognito.user_pool_id
    lambda_function_name      = module.lambda.lambda_function_name
    rds_proxy_endpoint        = module.rds.proxy_endpoint
    s3_bucket_name           = module.s3.bucket_name
    cloudwatch_dashboard     = module.cloudwatch.dashboard_url
    xray_service_map         = module.xray.xray_service_map_url
    guardduty_console        = module.guardduty.guardduty_console_url
  }
}


