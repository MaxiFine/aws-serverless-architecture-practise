/**
 * ============================================================================
 * API Gateway Module Outputs
 * ============================================================================
 * Output values from the API Gateway module for use by other modules.
 * ============================================================================
 */

output "api_gateway_id" {
  description = "ID of the API Gateway REST API"
  # value       = aws_api_gateway_rest_api.main.id
  value       = "${module.api_gateway.api_id}"
}

output "api_gateway_arn" {
  description = "ARN of the API Gateway REST API"
  # value       = aws_api_gateway_rest_api.main.arn
  value       = "${module.api_gateway.api_arn}"
}

output "api_gateway_execution_arn" {
  description = "Execution ARN of the API Gateway REST API"
  # value       = aws_api_gateway_rest_api.main.execution_arn
  value       = "${module.api_gateway.api_execution_arn}"
}

output "api_gateway_invoke_url" {
  description = "Invoke URL for the API Gateway stage"
  # value       = aws_api_gateway_stage.main.invoke_url
  value       = "${module.api_gateway.stage_invoke_url}"
}

output "api_gateway_domain_stage_name" {
  description = "Name of the API Gateway deployment stage"
  value       = "${module.api_gateway.stage_domain_name}"
}


output "api_gateway_endpoint" {
  value       = "${module.api_gateway.api_endpoint}/${var.stage_name}"
  description = "The base URL of the deployed API Gateway"
}

