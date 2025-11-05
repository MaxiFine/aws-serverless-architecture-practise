/**
 * ============================================================================
 * Lambda Module Outputs
 * ============================================================================
 * Output values from the Lambda module for use by other modules.
 * ============================================================================
 */

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.serverless_lambda.lambda_function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  # value       = aws_lambda_function.main.arn
  value       = module.serverless_lambda.lambda_function_arn
}

output "lambda_function_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = module.serverless_lambda.lambda_function_invoke_arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = module.serverless_lambda.lambda_role_arn
}

