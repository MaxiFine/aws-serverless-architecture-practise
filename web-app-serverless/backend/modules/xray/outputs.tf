/**
 * ============================================================================
 * Output values from the X-Ray module
 * ============================================================================
 */

output "xray_role_arn" {
  description = "ARN of the X-Ray IAM role"
  value       = aws_iam_role.xray_role.arn
}

output "xray_kms_key_arn" {
  description = "ARN of the X-Ray KMS encryption key"
  value       = aws_kms_key.xray.arn
}

output "xray_sampling_rule_arn" {
  description = "ARN of the X-Ray sampling rule"
  value       = aws_xray_sampling_rule.main.arn
}

output "xray_log_group_name" {
  description = "Name of the X-Ray CloudWatch log group"
  value       = aws_cloudwatch_log_group.xray_logs.name
}

output "xray_service_map_url" {
  description = "URL to the X-Ray service map console"
  value       = "https://${var.region}.console.aws.amazon.com/xray/home?region=${var.region}#/service-map"
}

output "xray_traces_url" {
  description = "URL to the X-Ray traces console"
  value       = "https://${var.region}.console.aws.amazon.com/xray/home?region=${var.region}#/traces"
}