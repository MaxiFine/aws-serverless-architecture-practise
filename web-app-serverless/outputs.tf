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
  value       = module.backend.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.backend.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.backend.private_subnet_ids
}

# Cognito Outputs
output "user_pool_id" {
  description = "ID of the Cognito User Pool"
  value       = module.backend.user_pool_id
}

output "user_pool_client_id" {
  description = "ID of the Cognito User Pool Client"
  value       = module.backend.user_pool_client_id
}

output "user_pool_domain" {
  description = "Domain of the Cognito User Pool"
  value       = module.backend.user_pool_domain
}

# API Gateway Outputs (replaces ALB for serverless)
output "api_gateway_invoke_url" {
  description = "API Gateway invoke URL"
  value       = module.backend.api_gateway_invoke_url
}

output "api_endpoint_url" {
  description = "API Gateway URL (replaces ALB DNS name in serverless architecture)"
  value       = module.backend.api_gateway_invoke_url
}


output "api_gateway_domain_stage_name" {
  description = "API Gateway domain stage name"
  value = module.backend.api_gateway_stage_domain_name
}


# RDS Outputs
output "rds_endpoint" {
  description = "RDS database endpoint"
  value       = module.backend.rds_endpoint
}

output "rds_proxy_endpoint" {
  description = "RDS Proxy endpoint"
  value       = module.backend.rds_proxy_endpoint
}

# S3 Outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.backend.s3_bucket_name
}

# Lambda Outputs
output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.backend.lambda_function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.backend.lambda_function_arn
}

# CloudWatch Outputs
output "cloudwatch_dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = module.backend.cloudwatch_dashboard_url
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = module.backend.sns_topic_arn
}

# X-Ray Outputs
output "xray_service_map_url" {
  description = "URL to the X-Ray service map"
  value       = module.backend.xray_service_map_url
}

output "xray_traces_url" {
  description = "URL to the X-Ray traces console"
  value       = module.backend.xray_traces_url
}

# GuardDuty Outputs
output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector"
  value       = module.backend.guardduty_detector_id
}

output "guardduty_console_url" {
  description = "URL to the GuardDuty console"
  value       = module.backend.guardduty_console_url
}

# Frontend Outputs
output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.frontend.cloudfront_domain_name
}

# Lambda@Edge Outputs
output "lambda_edge_arn" {
  description = "ARN of the Lambda@Edge function"
  value       = module.lambda_edge.lambda_edge_arn
}

# Deployment Summary
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    vpc_id                    = module.backend.vpc_id
    api_gateway_url           = module.backend.api_gateway_invoke_url
    cognito_user_pool_id      = module.backend.user_pool_id
    lambda_function_name      = module.backend.lambda_function_name
    rds_proxy_endpoint        = module.backend.rds_proxy_endpoint
    s3_bucket_name           = module.backend.s3_bucket_name
    cloudfront_domain         = module.frontend.cloudfront_domain_name
    cloudwatch_dashboard     = module.backend.cloudwatch_dashboard_url
    xray_service_map         = module.backend.xray_service_map_url
    guardduty_console        = module.backend.guardduty_console_url
  }
}

