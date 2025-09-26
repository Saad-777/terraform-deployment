
# Data source to fetch all available AZs in the region
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${terraform.workspace}-${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${terraform.workspace}-${var.project_name}-igw"
  }
}

# Public Subnets (one in each AZ)
resource "aws_subnet" "public" {
  count = length(data.aws_availability_zones.available.names)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${terraform.workspace}-${var.project_name}-public-subnet-${count.index + 1}-${data.aws_availability_zones.available.names[count.index]}"
    Type = "Public"
    AZ   = data.aws_availability_zones.available.names[count.index]
  }
}

# Private Subnets (one in each AZ)
resource "aws_subnet" "private" {
  count = length(data.aws_availability_zones.available.names)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 101)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${terraform.workspace}-${var.project_name}-private-subnet-${count.index + 1}-${data.aws_availability_zones.available.names[count.index]}"
    Type = "Private"
    AZ   = data.aws_availability_zones.available.names[count.index]
  }
}

# Elastic IP for NAT Gateway (only one)
resource "aws_eip" "nat" {
  domain = "vpc"

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${terraform.workspace}-${var.project_name}-nat-eip"
  }
}

# NAT Gateway (only one - placed in first public subnet)
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${terraform.workspace}-${var.project_name}-nat-gateway"
  }
}

# Public Route Table (shared by all public subnets)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${terraform.workspace}-${var.project_name}-public-rt"
    Type = "Public"
  }
}

# Associate all public subnets with the public route table
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Table (shared by all private subnets)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${terraform.workspace}-${var.project_name}-private-rt"
    Type = "Private"
  }
}

# Associate all private subnets with the single private route table
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}


# Web Security Group
resource "aws_security_group" "HTTP" {
  name_prefix = "${terraform.workspace}-${var.project_name}-HTTP-"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${terraform.workspace}-${var.project_name}-HTTP-sg"
  }
}

resource "aws_db_subnet_group" "wordpressRDS" {
  name       = "${terraform.workspace}-${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${terraform.workspace}-${var.project_name}-db-subnet-group"
  }
}


