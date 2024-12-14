# Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id = var.vpc_id
  count = length(var.availability_zone)
  cidr_block = cidrsubnet(var.vpc_cidr_block, 8, count.index+1)
  availability_zone = element(var.availability_zone,count.index)
  tags = {
    Name = "${var.project_name}-public-subnet-${element(var.availability_zone,count.index)}"
  }
}

# Private Subnet
resource "aws_subnet" "private_subnet"{
  vpc_id = var.vpc_id
  count = length(var.availability_zone)
  cidr_block = cidrsubnet(var.vpc_cidr_block, 8, count.index+3)
  availability_zone = element(var.availability_zone,count.index)
  tags = {
    Name = "${var.project_name}-private-subnet-${element(var.availability_zone,count.index)}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "couro_web_igw" {
  vpc_id = var.vpc_id
  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "my_rt" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.couro_web_igw.id
  }

  tags = {
    Name = "Public subnet Route Table"
  }
}

# Associate Route Table with Public Subnet
resource "aws_route_table_association" "public_subnet_association" {
  route_table_id = aws_route_table.my_rt.id
  count = length(var.availability_zone)
  subnet_id      = element(aws_subnet.public_subnet[*].id,count.index)
}

# Allocate an Elastic IP for the NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  depends_on = [ aws_internet_gateway.couro_web_igw ]
  tags = {
    Name = "nat-eip"
  }
}

# Create a NAT Gateway
resource "aws_nat_gateway" "couro_web_nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = element(aws_subnet.public_subnet[*].id,0)
  depends_on = [ aws_internet_gateway.couro_web_igw ]
  tags = {
    Name = "${var.project_name}-nat-gateway"
  }
}

# Create a route table for the private subnet
resource "aws_route_table" "private_route_table" {
  depends_on = [ aws_nat_gateway.couro_web_nat_gateway ]
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
resource "aws_route_table_association" "private_subnet_association" {
  route_table_id = aws_route_table.private_route_table.id
  count = length(var.availability_zone)
  subnet_id      = element(aws_subnet.private_subnet[*].id,count.index)
}


