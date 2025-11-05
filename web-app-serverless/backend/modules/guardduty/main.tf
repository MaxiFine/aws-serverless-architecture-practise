/**
 * ============================================================================
 * GuardDuty Module
 * ============================================================================
 * This module enables AWS GuardDuty for threat detection and security
 * monitoring of the serverless web application infrastructure including:
 * - Malicious activity detection
 * - Unusual API calls monitoring
 * ============================================================================
 */


# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Use existing GuardDuty detector
data "aws_guardduty_detector" "existing" {}


# Local value to get the detector ID
locals {
  detector_id = data.aws_guardduty_detector.existing.id
}


# GuardDuty S3 Protection Feature
resource "aws_guardduty_detector_feature" "s3_data_events" {
  count       = var.enable_s3_protection ? 1 : 0
  detector_id = local.detector_id
  name        = "S3_DATA_EVENTS"
  status      = "ENABLED"
}


# S3 Bucket for GuardDuty findings
resource "aws_s3_bucket" "guardduty_findings" {
  count  = var.enable_findings_export ? 1 : 0
  bucket = "${var.project_name}-guardduty-findings-${random_id.bucket_suffix.hex}"


  tags = merge(var.tags, {
    Name = "${var.project_name}-guardduty-findings"
  })
}


resource "random_id" "bucket_suffix" {
  byte_length = 4
}


resource "aws_s3_bucket_public_access_block" "guardduty_findings" {
  count  = var.enable_findings_export ? 1 : 0
  bucket = aws_s3_bucket.guardduty_findings[0].id


  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_server_side_encryption_configuration" "guardduty_findings" {
  count  = var.enable_findings_export ? 1 : 0
  bucket = aws_s3_bucket.guardduty_findings[0].id


  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


# S3 Bucket Policy for GuardDuty
resource "aws_s3_bucket_policy" "guardduty_findings" {
  count  = var.enable_findings_export ? 1 : 0
  bucket = aws_s3_bucket.guardduty_findings[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Allow GuardDuty to put objects"
        Effect = "Allow"
        Principal = {
          Service = "guardduty.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.guardduty_findings[0].arn}/*"
      },
      {
        Sid    = "Allow GuardDuty to get bucket ACL"
        Effect = "Allow"
        Principal = {
          Service = "guardduty.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.guardduty_findings[0].arn
      },
      {
        Sid    = "Allow GuardDuty to get bucket location"
        Effect = "Allow"
        Principal = {
          Service = "guardduty.amazonaws.com"
        }
        Action   = "s3:GetBucketLocation"
        Resource = aws_s3_bucket.guardduty_findings[0].arn
      }
    ]
  })
}


# CloudWatch Event Rule for GuardDuty findings
resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "${var.project_name}-guardduty-findings"
  description = "Capture GuardDuty findings"


  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
  })


  tags = merge(var.tags, {
    Name = "${var.project_name}-guardduty-event-rule"
  })
}

# SNS Topic for GuardDuty Alerts
resource "aws_sns_topic" "guardduty_alerts" {
  count = var.enable_sns_notifications ? 1 : 0
  name  = "${var.project_name}-guardduty-alerts"

  tags = merge(var.tags, {
    Name = "${var.project_name}-guardduty-alerts"
  })
}

# SNS Topic Policy to allow CloudWatch Events to publish
resource "aws_sns_topic_policy" "guardduty_alerts" {
  count = var.enable_sns_notifications ? 1 : 0
  arn   = aws_sns_topic.guardduty_alerts[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchEventsToPublish"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.guardduty_alerts[0].arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# Email subscription to SNS topic
resource "aws_sns_topic_subscription" "guardduty_email" {
  count     = var.enable_sns_notifications ? 1 : 0
  topic_arn = aws_sns_topic.guardduty_alerts[0].arn
  protocol  = "email"
  endpoint  = var.guardduty_alerts_email
}

# CloudWatch Event Target - SNS Topic
resource "aws_cloudwatch_event_target" "sns" {
  count     = var.enable_sns_notifications ? 1 : 0
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.guardduty_alerts[0].arn

  # Transform the GuardDuty finding into a more readable message
  input_transformer {
    input_paths = {
      severity    = "$.detail.severity"
      type        = "$.detail.type"
      region      = "$.detail.region"
      id          = "$.detail.id"
      description = "$.detail.description"
      title       = "$.detail.title"
      account     = "$.detail.accountId"
      time        = "$.detail.createdAt"
    }

    input_template = <<-EOT
{
  "GuardDuty Alert": {
    "Severity": "<severity>",
    "Finding Type": "<type>",
    "Title": "<title>",
    "Description": "<description>",
    "Account": "<account>",
    "Region": "<region>",
    "Time": "<time>",
    "Finding ID": "<id>"
  }
}
EOT
  }
}


# CloudWatch Log Group for GuardDuty events
resource "aws_cloudwatch_log_group" "guardduty_logs" {
  name              = "/aws/guardduty/${var.project_name}"
  retention_in_days = var.log_retention_days


  tags = merge(var.tags, {
    Name = "${var.project_name}-guardduty-logs"
  })
}



