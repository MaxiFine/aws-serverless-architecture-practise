/**
 * ============================================================================
 * Output values from the GuardDuty module
 * ============================================================================
 */

output "guardduty_detector_id" {
  description = "ID of the managed GuardDuty detector"
  value       = data.aws_guardduty_detector.existing.id
}

output "guardduty_detector_arn" {
  description = "ARN of the managed GuardDuty detector"
  value       = data.aws_guardduty_detector.existing.arn
}


output "guardduty_console_url" {
  description = "URL to the GuardDuty console"
  value       = "https://${var.region}.console.aws.amazon.com/guardduty/home?region=${var.region}#/findings"
}


output "guardduty_findings_bucket_name" {
  description = "Name of the S3 bucket for GuardDuty findings (if enabled)"
  value       = var.enable_findings_export ? aws_s3_bucket.guardduty_findings[0].bucket : null
}

output "guardduty_sns_topic_arn" {
  description = "ARN of the SNS topic for GuardDuty alerts (if enabled)"
  value       = var.enable_sns_notifications ? aws_sns_topic.guardduty_alerts[0].arn : null
}

output "guardduty_log_group_name" {
  description = "Name of the GuardDuty CloudWatch log group"
  value       = aws_cloudwatch_log_group.guardduty_logs.name
}

