# Simplified Networking Module - Direct Resource Configuration
# No complex logic, just use the exact numbers specified in variables

# Get available zones
data "aws_availability_zones" "available" {
  state = "available"
}


locals {
  egress_all = {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Simple locals - no complex calculations
locals {
  # Use exact counts from variables
  selected_azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-vpc"
      project     = var.project_name
      Target      = "Startups-Companies"
    }
  )
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-igw"
      project     = var.project_name
      Target      = "Startups-Companies"
    }
  )
}

# Public Subnets
resource "aws_subnet" "public" {
  count = var.public_subnets_total

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 100)
  availability_zone       = local.selected_azs[count.index % var.az_count]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-public-subnet-${count.index + 1}"
      Type        = "Public"
      Target      = "Startups-Companies"
      AZ          = local.selected_azs[count.index % var.az_count]
      Tier        = "Web"
    }
  ) 
}

# Private Subnets  
resource "aws_subnet" "private" {
  count = var.private_subnets_total

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 110)
  availability_zone = local.selected_azs[count.index % var.az_count]

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-private-subnet-${count.index + 1}"
      Type        = "Private"
      Target      = "Startups-Companies"
      AZ          = local.selected_azs[count.index % var.az_count]
      Tier        = "Application"
    }
  )
}

# Database Subnets (Optional)
resource "aws_subnet" "database" {
  count = var.database_subnets_total

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 20)
  availability_zone = local.selected_azs[count.index % var.az_count]

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-database-subnet-${count.index + 1}"
      Type        = "Database"
      Target      = "Startups-Companies"
      AZ          = local.selected_azs[count.index % var.az_count]
      Tier        = "Database"
    }
  )
}

# Elastic IP for NAT Gateway(s)
resource "aws_eip" "nat" {
  count = var.nat_gateways_total

  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-nat-eip-${count.index + 1}"
      Type        = "Private-Communications"
      Target      = "Startups-Companies"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count = var.nat_gateways_total

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index % var.public_subnets_total].id

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-nat-${count.index + 1}"
      Type        = "Private-Communications"
      Target      = "Startups-Companies"
      AZ          = local.selected_azs[count.index % var.az_count]
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# Public Route Tables
resource "aws_route_table" "public" {
  count = var.public_route_tables_total

  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    var.tags,
    {
      Name   = "${var.project_name}-public-rt-${count.index + 1}"
      Type   = "Public"
      Target = "Startups-Companies"
      Tier   = "Web"
    }
  )
}

# Private Route Tables
resource "aws_route_table" "private" {
  count = var.private_route_tables_total

  vpc_id = aws_vpc.main.id

  # Add NAT route if NAT Gateways exist
  dynamic "route" {
    for_each = var.nat_gateways_total > 0 ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[count.index % var.nat_gateways_total].id
    }
  }

  tags = merge(
    var.tags,
    {
      Name   = "${var.project_name}-private-rt-${count.index + 1}"
      Type   = "Private"
      Target = "Startups-Companies"
      Tier   = "Application"
    }
  )
}

# Database Route Tables (no internet access by default)
# resource "aws_route_table" "database" {
#   count = var.database_route_tables_total

#   vpc_id = aws_vpc.main.id

#   tags = merge(
#     var.tags,
#     {
#       Name   = "${var.project_name}-database-rt-${count.index + 1}"
#       Type   = "Database"
#       Target = "Startups-Companies"
#       Tier   = "Database"
#     }
#   )
# }

# Associate public subnets with public route tables
resource "aws_route_table_association" "public" {
  count = var.public_subnets_total

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[count.index % var.public_route_tables_total].id
}

# Associate private subnets with private route tables
resource "aws_route_table_association" "private" {
  count = var.private_subnets_total

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index % var.private_route_tables_total].id
}

# # Associate database subnets with database route tables
# resource "aws_route_table_association" "database" {
#   count = var.database_subnets_total

#   subnet_id      = aws_subnet.database[count.index].id
#   route_table_id = aws_route_table.database[count.index % var.database_route_tables_total].id
# }

# # Database Subnet Group (for RDS/Aurora)
# resource "aws_db_subnet_group" "database" {
#   count = var.database_subnets_total > 0 ? 1 : 0

#   name       = "${var.project_name}-database-subnet-group"
#   subnet_ids = aws_subnet.database[*].id

#   tags = merge(
#     var.tags,
#     {
#       Name   = "${var.project_name}-database-subnet-group"
#       Type   = "Database"
#       Target = "Startups-Companies"
#       Tier   = "Database"
#     }
#   )
# }


##################
## SECURITY GROUPS
/** 
 * ----------------------------
 * SECURITY GROUP (Lambda + RDS)
 * ----------------------------
 * Security group allowing Lambda to communicate with RDS on port 3306.
 */
resource "aws_security_group" "lambda_rds_sg" {
  name        = "${var.project_name}-lambda-rds-sg"
  description = "Security group for Lambda and RDS"
  vpc_id      = aws_vpc.main.id

  # ingress {
  #   from_port = 3306
  #   to_port   = 3306
  #   protocol  = "tcp"
  #   self      = true
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project_name}-lambda-rds-sg" })
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private[0].id]
  tags              = merge(var.tags, { Name = "${var.project_name}-s3-endpoint" })
}


# ====================================================
# PROXY SECURITY GROU
# ====================================================

resource "aws_security_group" "proxy_sg" {
  name        = "${var.project_name}-proxy-sg"
  description = "Allow DB access from Private SG only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "DB access from Private SG on port ${var.db_port}"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_rds_sg.id, aws_security_group.public_sg.id]
  }

  ingress {
    description = "Allow ICMP (ping) from VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = local.egress_all.from_port
    to_port     = local.egress_all.to_port
    protocol    = local.egress_all.protocol
    cidr_blocks = local.egress_all.cidr_blocks
  }

  tags = merge(var.tags, {
    Name         = "Database Security Group"
    ResourceName = "Database-SG"
  })
}





# ====================================================
# DATABASE SECURITY GROUP (DB LAYER)
# ====================================================

resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-db-sg"
  description = "Allow DB access from Private SG only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "DB access from Private SG on port ${var.db_port}"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.proxy_sg.id]
  }
  ingress {
    description     = "ssh access from Private SG on port ${var.db_port}"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.proxy_sg.id, aws_security_group.lambda_rds_sg.id, aws_security_group.public_sg.id,]
  }

  ingress {
    description = "Allow ICMP (ping) from VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = local.egress_all.from_port
    to_port     = local.egress_all.to_port
    protocol    = local.egress_all.protocol
    cidr_blocks = local.egress_all.cidr_blocks
  }

  tags = merge(var.tags, {
    Name         = "Database Security Group"
    ResourceName = "Database-SG"
  })
}


##############
## PUBLIC SG
resource "aws_security_group" "public_sg" {
  name        = "${var.project_name}-public-sg"
  description = "Security group for public resources"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project_name}-public-sg" })
}

