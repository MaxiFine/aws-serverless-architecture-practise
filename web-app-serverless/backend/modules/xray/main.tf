/**
 * ============================================================================
 * X-Ray Module
 * ============================================================================
 * This module configures AWS X-Ray for distributed tracing of:
 * - Lambda functions
 * - API Gateway requests
 * - Database connections
 * ============================================================================
 */

# X-Ray Encryption Configuration
resource "aws_xray_encryption_config" "main" {
  type   = "KMS"
  key_id = aws_kms_key.xray.arn
}

# KMS Key for X-Ray encryption
resource "aws_kms_key" "xray" {
  description             = "KMS key for X-Ray encryption"
  deletion_window_in_days = 7

  tags = merge(var.tags, {
    Name = "${var.project_name}-xray-kms-key"
  })
}

resource "aws_kms_alias" "xray" {
  name          = "alias/${var.project_name}-xray"
  target_key_id = aws_kms_key.xray.key_id
}

# X-Ray Sampling Rule for cost optimization
resource "aws_xray_sampling_rule" "main" {
  rule_name      = "${var.project_name}-sampling-rule"
  priority       = 9000
  version        = 1
  reservoir_size = 1
  fixed_rate     = 0.1
  url_path       = "*"
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = "*"
  resource_arn   = "*"

  tags = merge(var.tags, {
    Name = "${var.project_name}-xray-sampling-rule"
  })
}

# IAM Role for X-Ray service
resource "aws_iam_role" "xray_role" {
  name = "${var.project_name}-xray-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "apigateway.amazonaws.com"
          ]
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-xray-role"
  })
}

# X-Ray write permissions policy
resource "aws_iam_role_policy" "xray_write_policy" {
  name = "${var.project_name}-xray-write-policy"
  role = aws_iam_role.xray_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets",
          "xray:GetSamplingStatisticSummaries"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach AWS managed X-Ray policy
resource "aws_iam_role_policy_attachment" "xray_daemon_write_access" {
  role       = aws_iam_role.xray_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# CloudWatch Log Group for X-Ray
resource "aws_cloudwatch_log_group" "xray_logs" {
  name              = "/aws/xray/${var.project_name}"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.project_name}-xray-logs"
  })
}

# Optional: X-Ray Service Map insights
resource "aws_xray_sampling_rule" "high_priority_endpoints" {
  count = var.enable_detailed_tracing ? 1 : 0
  
  rule_name      = "${var.project_name}-high-priority-sampling"
  priority       = 5000
  version        = 1
  reservoir_size = 2
  fixed_rate     = 0.5
  url_path       = "/api/*"
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = "*"
  resource_arn   = "*"

  tags = merge(var.tags, {
    Name = "${var.project_name}-high-priority-xray-sampling"
  })
}