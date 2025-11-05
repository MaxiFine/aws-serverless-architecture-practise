# VPC Networking Deployment Outputs
# Essential networking information for development teams

# Main networking information
output "networking_info" {
  description = "Essential networking information for development teams"
  value = {
    # VPC Details
    vpc_id   = aws_vpc.main.id
    vpc_cidr = aws_vpc.main.cidr_block

    # Subnet IDs for deploying resources
    public_subnet_ids  = aws_subnet.public[*].id
    private_subnet_ids = aws_subnet.private[*].id

    # First subnet IDs (commonly used)
    public_subnet_id  = aws_subnet.public[0].id
    private_subnet_id = aws_subnet.private[0].id

    # Infrastructure details
    availability_zones = data.aws_availability_zones.available.names
    nat_gateway_id     = aws_nat_gateway.main[0].id

    # Security Groups
    public_security_group_id  = aws_security_group.public_sg.id
    # private_security_group_id = aws_security_group.private.id

  }
}

# Deployment summary
output "deployment_summary" {
  description = "VPC deployment summary"
  value = {
    project_name         = var.project_name
    vpc_cidr            = var.vpc_cidr
    # availability_zones  = length(aws_availability_zones.available)
    public_subnets      = length(aws_subnet.public[*].id)
    private_subnets     = length(aws_subnet.private[*].id)
    nat_gateways_total  = var.nat_gateways_total
    multi_az_enabled    = var.az_count > 1
  }
}

# Individual outputs for easy reference
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

# output "public_subnet_ids" {
#   description = "First public subnet ID (commonly used)"
#   value       = aws_subnet.public[*].id
# }

# output "private_subnet_ids" {
#   description = "First private subnet ID (commonly used)"
#   value       = aws_subnet.private[*].id
# }

output "availability_zones" {
  description = "Availability zones used"
  value       = data.aws_availability_zones.available
}

output "nat_gateway_id" {
  description = "NAT Gateway ID (if enabled)"
  value       = aws_nat_gateway.main[*].id
}

# Security Group Outputs
output "public_security_group_id" {
  description = "ID of the public security group"
  value       = aws_security_group.public_sg.id
}

output "lambda_security_group_id" {
  description = "ID of the Lambda security group"
  value       = aws_security_group.lambda_rds_sg.id
}

output "proxy_security_group_id" {
  description = "ID of the Proxy security group"
  value       = aws_security_group.proxy_sg.id
}

# output "lambda_security_group_id" {
#   description = "ID of the RDS security group"
#   value       = aws_security_group.db_sg.id
# }

# output "all_security_group_ids" {
#   description = "All created security group IDs"
#   value       = [aws_security_group.public.id, aws_security_group.private.id,           aws_security_group.db_sg.id, aws_security_group.lambda_rds_sg.id,aws_security_group.proxy_sg.id
#   ]
# }

# Usage information
output "usage_info" {
  description = "Information on how to use this VPC infrastructure"
  value = {
    vpc_ready = "VPC networking infrastructure is ready"
    components = {
      vpc              = "VPC with Internet Gateway"
      public_subnets   = "Public subnets for web-facing resources"
      private_subnets  = "Private subnets for backend resources"
      nat_gateways     = var.nat_gateways_total > 0 ? "${var.nat_gateways_total} NAT Gateway(s) for private subnet internet access" : "-----Disabled------"
      security_groups  = "Pre-configured security groups, can be customized further."
    }
    architecture = "Internet → IGW → Public Subnets → NAT Gateway → Private Subnets"
  }
}

#####################
## OLD OUTPUTS BELOW ##
# output "vpc_id" {
#   description = "The ID of the created VPC"
#   value       = aws_vpc.this.id
# }

output "vpc_cidr_block" {
  description = "The CIDR block associated with the VPC"
  value       = aws_vpc.main.cidr_block
}

# output "private_subnet_ids" {
#   description = "List of IDs of all private subnets for Lambda, RDS, and RDS Proxy"
#   value       = aws_subnet.private[*].id
# }

output "private_subnet_cidrs" {
  description = "List of CIDR blocks for the private subnets"
  value       = aws_subnet.private[*].cidr_block
}

# output "public_subnet_id" {
#   description = "The ID of the public subnet if a NAT Gateway is created, else null"
#   value       = module.backend.vpc.public_subnet_id[*].cidr_block
# }

# output "nat_gateway_id" {
#   description = "The ID of the NAT Gateway if created, else null"
#   value       = var.create_nat_gateway ? aws_nat_gateway.this[0].id : null
# }


output "s3_vpc_endpoint_id" {
  description = "The ID of the S3 Gateway VPC Endpoint providing private S3 access"
  value       = aws_vpc_endpoint.s3.id
}


output "rds_security_group_id" {
  description = "Database Security Group for Connections"
  value = aws_security_group.db_sg.id
}

# output "lambda_security_group_id" {
#   description = "Security Group for Lambda to RDS Connections"
#   value = aws_security_group.lambda_rds_sg.id
# }

output "proxy_sg_id" {
  description = "Security Group for Proxy"
  value = aws_security_group.proxy_sg.id
}
