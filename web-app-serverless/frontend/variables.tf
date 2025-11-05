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

variable "cloudfront_price_class" {
  description = <<EOT
CloudFront price class. Determines the edge locations used for content delivery:

  - PriceClass_100: Only US, Canada, and Europe edge locations. Lowest cost.
  - PriceClass_200: US, Canada, Europe, and Asia Pacific edge locations. Moderate cost.
  - PriceClass_All: All edge locations worldwide. Highest cost, best global coverage.
EOT
  type        = string
}

variable "default_root_object" {
  description = "Default object to serve (e.g. index.html). Leave empty if not required."
  type        = string
}

variable "cloudfront_alias" {
  description = "The CNAME for the CloudFront distribution"
  type        = string
}

variable "api_gateway_url" {
  description = "The domain name of the API Gateway to use as an additional origin"
  type        = string
}

variable "lambda_edge_arn" {
  description = "Qualified ARN of the Lambda@Edge version to associate"
  type        = string
}

variable "api_stage_name" {
  description = "API Gateway deployment stage name"
  type        = string
}