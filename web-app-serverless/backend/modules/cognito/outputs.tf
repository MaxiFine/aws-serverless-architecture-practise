output "user_pool_id" {
  value       = aws_cognito_user_pool.user_pool.id
  description = "The ID of the Cognito User Pool"
}

output "user_pool_client_id" {
  value       = aws_cognito_user_pool_client.user_pool_client.id
  description = "The ID of the Cognito User Pool Client"
}

output "user_pool_client_secret" {
  value       = aws_cognito_user_pool_client.user_pool_client.client_secret
  description = "The secret of the Cognito User Pool Client"
}

output "user_pool_arn" {
  value       = aws_cognito_user_pool.user_pool.arn
  description = "The ARN of the Cognito User Pool"
}

output "user_pool_domain" {
  value       = aws_cognito_user_pool_domain.user_pool_domain.domain
  description = "The domain of the Cognito User Pool"
}