variable "vpc_id" {
  type = string
}

resource "aws_subnet" "private_subnet_ap_south_1a" {
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  vpc_id            = var.vpc_id
  tags = {
    Name = "private-subnet-ap-south-1a"
  }
}

resource "aws_subnet" "public_subnet_ap_south_1a" {
  cidr_block            = "10.0.2.0/24"
  availability_zone     = "ap-south-1a"
  vpc_id                = var.vpc_id
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-ap-south-1a"
  }
}

resource "aws_subnet" "public_subnet_ap_south_1b" {
  cidr_block            = "10.0.3.0/24"
  availability_zone     = "ap-south-1b"
  vpc_id                = var.vpc_id
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-ap-south-1b"
  }
}

output "private_subnet_id" {
  value = aws_subnet.private_subnet_ap_south_1a.id
}

output "public_subnet_ids" {
  value = [aws_subnet.public_subnet_ap_south_1a.id, aws_subnet.public_subnet_ap_south_1b.id]
}