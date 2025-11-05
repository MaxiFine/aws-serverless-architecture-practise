/**
 * ============================================================================
 *  AWS CloudFront Distribution with S3 (OAC), and Lambda@Edge
 *  ----------------------------------------------------------------------------
 *  Provisions a CloudFront distribution that serves static content from S3 via
 *  Origin Access Control (OAC), routes API traffic under `/api/*` to an API Gateway,
 *  and attaches a Lambda@Edge (viewer-request) function for authentication.
 *
 *  Key Features:
 *    - Creates an Origin Access Control (OAC) to restrict direct S3 access.
 *    - Delivers static frontend assets from the S3 bucket via CloudFront.
 *    - Routes dynamic requests under `/api/*` to the API Gateway origin.
 *    - Attaches Lambda@Edge on viewer-request for both default and /api/* paths.
 *    - Enforces HTTPS and uses an AWS-managed caching policy (by ID) for performance.
 *    - Supports optional custom domain aliases and flexible price classes.
 *
 *  Required Variables:
 *    - var.s3_origin_id            → Unique identifier for the S3 origin.
 *    - var.s3_bucket_domain        → Domain name of the S3 bucket.
 *    - var.default_root_object     → Default root object (e.g., index.html).
 *    - var.cloudfront_price_class  → CloudFront pricing tier (e.g., PriceClass_100).
 *    - var.api_gateway_url         → Domain name of the API Gateway for API routing.
 *    - var.lambda_edge_arn         → Versioned ARN for the Lambda@Edge function (us-east-1).
 *    - var.project_name            → Project identifier for tagging.
 *
 *  Optional Variables:
 *    - var.cloudfront_aliases      → Custom domain names (requires ACM cert in us-east-1).
 *    - var.tags                    → Additional resource tags.
 *
 *  Notes:
 *    - When using aliases, you must configure viewer_certificate with an ACM
 *      certificate issued in us-east-1 and set `aliases` accordingly.
 *    - The API Gateway origin uses HTTP from CloudFront to origin (origin_protocol_policy=http-only)
 *      while enforcing HTTPS from viewer to CloudFront (viewer_protocol_policy=redirect-to-https).
 * ============================================================================
 */

# Create an Origin Access Control (OAC) to secure the S3 bucket
resource "aws_cloudfront_origin_access_control" "website_oac" {
  name                              = "${var.s3_origin_id}-oac"
  description                       = "OAC for S3 origin ${var.s3_origin_id}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Create the CloudFront distribution
resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled = true
  # aliases = var.cloudfront_aliases
  default_root_object = var.default_root_object
  price_class         = var.cloudfront_price_class

  # Define the S3 origin with OAC
  origin {
    domain_name              = var.s3_bucket_domain
    origin_id                = var.s3_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.website_oac.id
  }

  # Define the API Gateway origin (API Gateway in serverless architecture)
  origin {
    domain_name = "${var.api_gateway_url}"
    origin_id   = "api-gateway-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Default Behavior (Static content from S3)
  default_cache_behavior {
    target_origin_id       = var.s3_origin_id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"

    # Associate Lambda@Edge for authentication/authorization at viewer request
    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = var.lambda_edge_arn
      include_body = false
    }
  }

  # Behavior for /dev/* (Forward to API Gateway)
  ordered_cache_behavior {
    path_pattern           = "/${var.api_stage_name}/*"
    target_origin_id       = "api-gateway-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = true
      headers      = ["Authorization"]
      cookies {
        forward = "all"
      }
    }

    # Also run Lambda@Edge for API requests to enforce auth where required
    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = var.lambda_edge_arn
      include_body = false
    }
  }


  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.s3_origin_id}-oac"
    }
  )
}

