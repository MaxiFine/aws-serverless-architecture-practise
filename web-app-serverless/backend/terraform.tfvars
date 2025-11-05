# # Simplified VPC Networking Configuration
# # Direct resource count specification - no complex logic

# # Basic Configuration
# package_name = "networking-package"
# aws_region   = "eu-west-1"
# vpc_cidr     = "10.0.0.0/16"

# # Infrastructure Counts (specify exact numbers you want)
# az_count                      = 2  # Use 2 availability zones
# public_subnets_total          = 2  # 2 public subnets total (1 per AZ)
# private_subnets_total         = 2  # 2 private subnets total (1 per AZ)
# database_subnets_total        = 0  # 0 database subnets (2-tier architecture)

# # NAT Gateway Configuration  
# nat_gateways_total            = 1  # 1 NAT Gateway total (cost-optimized)

# # Route Table Configuration
# public_route_tables_total     = 1  # 1 public route table (shared)
# private_route_tables_total    = 1  # 1 private route table (shared)
# database_route_tables_total   = 0  # 0 database route tables (no database tier)

# # Security Groups
# create_public_sg  = true
# create_private_sg = true

# # Security Group Rules
# public_ingress_rules = [
#   {
#     description = "HTTP"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   },
#   {
#     description = "HTTPS"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# ]

# # � VPC NETWORKING COMPONENTS:
# #
# # ✅ What's Included:
# # - VPC with Internet Gateway
# # - Public subnet for web-facing resources
# # - Private subnet for backend resources
# # - NAT Gateway for private subnet internet access:DISABLED
# # - Security groups with HTTP/HTTPS rules
# # - Complete networking foundation
# #
# # 🏗️ Architecture Flow:
# # Internet → Internet Gateway → Public Subnet → NAT Gateway → Private Subnet
# #
# # 💰 Cost Optimization:
# # - Single AZ deployment reduces NAT Gateway costs
# # - No compute resources or VPC endpoints
# # - Only essential networking components
# #
# # 🚀 Ready for Application Deployment:
# # Use the subnet IDs and security group IDs from outputs to deploy your applications!

#################
# SINGLE DEPLOYMENT TESTING

# Example 1: Single AZ, Cost-Optimized (Minimal Setup)
# Perfect for development environments or small applications



# vpc_cidr     = "10.0.0.0/16"

# # Infrastructure Counts
# az_count                      = 1  # Single AZ
# public_subnets_total          = 1  # 1 public subnet
# private_subnets_total         = 1  # 1 private subnet
# database_subnets_total        = 0  # No database tier

# # NAT Gateway Configuration  
# nat_gateways_total            = 0  # 1 NAT Gateway (required for private subnet internet access)

# # Route Table Configuration
# public_route_tables_total     = 1  # 1 public route table
# private_route_tables_total    = 1  # 1 private route table
# database_route_tables_total   = 0  # No database route tables

# # Security Groups


# 💰 COST: ~$45/month (1 NAT Gateway)
# 🏗️ ARCHITECTURE: Single AZ, 2-tier (web/app)
# 🎯 USE CASE: Development, MVP, small applications