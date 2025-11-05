output "db_endpoint" {
  value = aws_db_instance.this.address
}

output "db_instance_identifier" {
  description = "RDS instance identifier"
  value       = aws_db_instance.this.identifier
}

output "proxy_endpoint" {
  value = aws_db_proxy.this.endpoint
}

output "db_secret_arn" {
  value = aws_db_instance.this.master_user_secret[0].secret_arn
}

output "db_identifier" {
  description = "RDS database identifier"
  value       = aws_db_instance.this.identifier
}

output "db_resource_id" {
  description = "RDS database resource ID (use for rds-db:connect ARN)"
  value       = aws_db_instance.this.resource_id
}

output "db_username" {
  description = "RDS database master username"
  value       = aws_db_instance.this.username
}   

output "db_host" {
  description = "RDS database host"
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "RDS database port"
  value       = aws_db_instance.this.port
} 

output "db_name" {
  description = "RDS database name"
  value       = aws_db_instance.this.db_name
}



output "rds_proxy_id" {
  description = "RDS Proxy ID"
  value       = aws_db_proxy.this.name
}

output "rds_proxy_arn" {
  description = "RDS Proxy ARN"
  value       = aws_db_proxy.this.arn
}
