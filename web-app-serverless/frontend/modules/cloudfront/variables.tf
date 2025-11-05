variable "region" {
  description = "AWS region for the S3 bucket (CloudFront is global)."
  type        = string
}

variable "project_name" {
  description = "Name of the project (used for resource naming and tagging)."
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

variable "s3_origin_id" {
  description = "The ID of the S3 bucket to use as the origin"
  type        = string
}

variable "s3_bucket_domain" {
  description = "The S3 bucket's regional domain name"
  type        = string
}

variable "s3_bucket_arn" {
  description = "The ARN of the S3 bucket"
  type        = string
}

variable "cloudfront_aliases" {
  description = "List of CNAMEs for the distribution"
  type        = list(string)
  default     = []
}

variable "default_root_object" {
  description = "The default root object for the CloudFront distribution"
  type        = string
}

variable "cloudfront_price_class" {
  description = "The price class for the CloudFront distribution"
  type        = string
  
}

variable "api_gateway_url" {
  description = "The domain name of the API Gateway to use as an additional origin"
  type        = string
}

variable "lambda_edge_arn" {
  description = "The ARN of the Lambda@Edge function for authentication"
  type        = string
}


variable "api_stage_name" {
  description = "API Gateway deployment stage name"
  type        = string
}