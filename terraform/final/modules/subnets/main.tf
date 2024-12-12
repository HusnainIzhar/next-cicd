# Private Subnet in us-east-1a
resource "aws_subnet" "private_subnet_us_east_1a" {
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.region.a1
  vpc_id            = var.vpc_id
  tags = {
    Name = "${var.project_name}-private-subnet-${var.region.a1}"
  }
}

# Private Subnet in us-east-1b
resource "aws_subnet" "private_subnet_us_east_1b" {
  cidr_block        = "10.0.2.0/24"
  availability_zone = var.region.b1
  vpc_id            = var.vpc_id
  tags = {
    Name = "${var.project_name}-private-subnet-${var.region.b1}"
  }
}

# Public Subnet in us-east-1a
resource "aws_subnet" "public_subnet_us_east_1a" {
  cidr_block            = "10.0.3.0/24"
  availability_zone     = var.region.a1
  vpc_id                = var.vpc_id
  map_public_ip_on_launch = true
  tags = {
    Name =  "${var.project_name}-public-subnet-${var.region.a1}"
  }
}

# Public Subnet in us-east-1b
resource "aws_subnet" "public_subnet_us_east_1b" {
  cidr_block            = "10.0.4.0/24"
  availability_zone     = var.region.b1
  vpc_id                = var.vpc_id
  map_public_ip_on_launch = true
  tags = {
    Name =  "${var.project_name}-public-subnet-${var.region.b1}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "couro_web_igw" {
  vpc_id = var.vpc_id
  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Allocate an Elastic IP for the NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "nat-eip"
  }
}

# Create a NAT Gateway in the public subnet
resource "aws_nat_gateway" "couro_web_nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_us_east_1a.id

  tags = {
    Name = "${var.project_name}-nat-gateway"
  }
}

# Create a route table for the private subnet
resource "aws_route_table" "private_route_table" {
  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.couro_web_nat_gateway.id
  }

  tags = {
    Name = "private-route-table"
  }
}

# Associate the private subnet with the route table
resource "aws_route_table_association" "private_subnet_us_east_1a_route_association" {
  route_table_id = aws_route_table.private_route_table.id
  subnet_id      = aws_subnet.private_subnet_us_east_1a.id
}

# Associate the private subnet with the route table
resource "aws_route_table_association" "private_subnet_us_east_1b_route_association" {
  route_table_id = aws_route_table.private_route_table.id
  subnet_id      = aws_subnet.private_subnet_us_east_1b.id
}

# Route Table for Public Subnets
resource "aws_route_table" "my_rt" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.couro_web_igw.id
  }

  tags = {
    Name = "main-route-table"
  }
}

# Associate Route Table with Public Subnet in us-east-1a
resource "aws_route_table_association" "public_subnet_us_east_1a" {
  route_table_id = aws_route_table.my_rt.id
  subnet_id      = aws_subnet.public_subnet_us_east_1a.id
}

# Associate Route Table with Public Subnet in us-east-1b
resource "aws_route_table_association" "public_subnet_us_east_1b" {
  route_table_id = aws_route_table.my_rt.id
  subnet_id      = aws_subnet.public_subnet_us_east_1b.id
}
