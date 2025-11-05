# resource "terraform_data" "init_iam_user" {
#   provisioner "local-exec" {
#     command = <<EOT
#       mysql -h ${aws_db_proxy.example.endpoint} -u admin -p"${var.db_admin_password}" -e "ALTER USER 'admin'@'%' IDENTIFIED WITH AWSAuthenticationPlugin AS 'RDS'; GRANT rds_iam TO 'admin'@'%';"
#     EOT
#   }
# }



# Use AWS managed secret for RDS credentials
data "aws_secretsmanager_secret" "db_secret" {
  arn = aws_db_instance.this.master_user_secret[0].secret_arn
}

data "aws_secretsmanager_secret_version" "db_secret_value" {
  secret_id = data.aws_secretsmanager_secret.db_secret.id
}

# Subnet Group
resource "aws_db_subnet_group" "this" {
  name       = lower(replace("${var.project_name}-db-subnet", "_", "-"))
  subnet_ids = var.private_subnets
}

# RDS instance
resource "aws_db_instance" "this" {
  identifier         = lower(replace("${var.project_name}-db", "_", "-"))
  engine             = "mysql"
  engine_version     = "8.0"
  instance_class     = "db.t3.micro"
  allocated_storage  = 20
  username           = var.db_username
  manage_master_user_password = true
  db_name            = "appdb"
  skip_final_snapshot = true
  vpc_security_group_ids = [var.rds_security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.this.name
  iam_database_authentication_enabled = true

  # Ensure this is destroyed before security groups
  lifecycle {
    create_before_destroy = false
  }
}

# IAM role for RDS Proxy
resource "aws_iam_role" "proxy_role" {
  name = "${var.project_name}-rds-proxy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "rds.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "proxy_secrets_read" {
  name = "${var.project_name}-rds-proxy-secrets-read"
  role = aws_iam_role.proxy_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["secretsmanager:GetSecretValue"],
        Resource = aws_db_instance.this.master_user_secret[0].secret_arn
      }
    ]
  })
}

# RDS Proxy
resource "aws_db_proxy" "this" {
  name                   = lower(replace("${var.project_name}-proxy", "_", "-"))
  engine_family          = "MYSQL"
  role_arn               = aws_iam_role.proxy_role.arn
  vpc_security_group_ids = [var.proxy_security_group_id]
  vpc_subnet_ids         = var.private_subnets
  require_tls            = true
  idle_client_timeout    = 1800

  auth {
    auth_scheme               = "SECRETS"
    # client_password_auth_type = "MYSQL_CACHING_SHA2_PASSWORD"
    iam_auth                  = "REQUIRED"
    secret_arn                = aws_db_instance.this.master_user_secret[0].secret_arn
  }

  # default_auth_scheme = "IAM_AUTH"

  # lifecycle {
  #   ignore_changes = [
  #     auth
  #   ]
  #   create_before_destroy = false
  # }

  tags = var.tags
}

resource "aws_db_proxy_target" "target" {
  db_proxy_name       = aws_db_proxy.this.name
  target_group_name   = "default"
  db_instance_identifier = aws_db_instance.this.identifier
  
  # Ensure this is destroyed before security groups
  lifecycle {
    create_before_destroy = false
  }
}
