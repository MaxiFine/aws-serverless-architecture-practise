
/**
  Terraform for Lambda@Edge authenticator used by CloudFront in the web-ec2-scenario.

  What it does:
  - Writes a config.json (local_file) consumed by the ESM handler bundle (no env vars at Edge)
  - Zips the lambda_functions directory into a deployment artifact
  - Creates IAM role and inline policy for logging
  - Deploys a Node.js 22.x Lambda function (published=true) in us-east-1 for Lambda@Edge
  - Grants CloudFront edge service permission to replicate the function

  Key inputs (from variables):
  - user_pool_domain, user_pool_client_id, user_pool_id, region, protected_rules
  - Redirect path defaulted to /callback; SCOPES set to "openid email profile"

  Notes:
  - Lambda@Edge must be created in us-east-1; a regional alias/provider is configured at the root module
  - The function reads config.json at runtime; ensure archive_file depends_on the local_file
*/
# Write config.json used by the Lambda@Edge function (no env vars at Edge)
resource "local_file" "config_json" {
  content = jsonencode({
    # Build full Hosted UI domain: <domain-prefix>.auth.<region>.amazoncognito.com
    COGNITO_DOMAIN = "${var.user_pool_domain}.auth.${var.region}.amazoncognito.com",
    CLIENT_ID      = var.user_pool_client_id,
    USER_POOL_ID   = var.user_pool_id,
    REGION         = var.region,
    SCOPES         = "openid email profile",
    REDIRECT_PATH   = "/callback",
    PROTECTED_RULES = var.protected_rules
  })
  filename        = "${path.module}/lambda_functions/config.json"
  file_permission = "0644"
}

data "archive_file" "lambda_auth_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_functions"
  output_path = "${path.module}/lambda_functions.zip"
  depends_on  = [local_file.config_json]
}

# IAM Role for Lambda@Edge
resource "aws_iam_role" "lambda_auth_role" {
  provider = aws.us_east_1
  name     = var.project_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "edgelambda.amazonaws.com"
          ]
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach permissions policy to the role (e.g., for Secrets Manager access)
resource "aws_iam_role_policy" "lambda_auth_policy" {
  provider = aws.us_east_1
  name     = "lambda_auth_policy"
  role     = aws_iam_role.lambda_auth_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "random_id" "lambda_id" {
  byte_length = 4
}

resource "aws_lambda_function" "lambda_auth" {
  provider      = aws.us_east_1
  function_name = "${var.project_name}-${random_id.lambda_id.hex}"
  role          = aws_iam_role.lambda_auth_role.arn
  handler       = "index.handler"
  runtime       = "nodejs22.x"
  memory_size   = 128
  timeout       = 30

  filename         = data.archive_file.lambda_auth_zip.output_path
  source_code_hash = data.archive_file.lambda_auth_zip.output_base64sha256

  publish = true
}

# Allow CloudFront's edge service to access the function for replication
resource "aws_lambda_permission" "allow_cloudfront" {
  provider      = aws.us_east_1
  statement_id  = "AllowExecutionFromCloudFront"
  action        = "lambda:GetFunction"
  function_name = aws_lambda_function.lambda_auth.function_name
  principal     = "edgelambda.amazonaws.com"
}
