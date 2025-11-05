output "lambda_edge_arn" {
  value       = aws_lambda_function.lambda_auth.qualified_arn
  description = "The ARN of the Lambda@Edge function for authentication"
}