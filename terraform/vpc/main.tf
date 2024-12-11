# Initialize Terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.54.1"
    }
  }
  backend "s3" {
    bucket = "mybucket12vpc"
    key    = "backend.tfstate"
    region = "ap-south-1"
  }
}

# AWS Provider Configuration
provider "aws" {
  region = "ap-south-1"
}

# Create a VPC
resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "myvpc"
  }
}

# Private Subnet in ap-south-1a
resource "aws_subnet" "private_subnet_ap_south_1a" {
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  vpc_id            = aws_vpc.myvpc.id
  tags = {
    Name = "private-subnet-ap-south-1a"
  }
}

# Public Subnet in ap-south-1a
resource "aws_subnet" "public_subnet_ap_south_1a" {
  cidr_block            = "10.0.2.0/24"
  availability_zone     = "ap-south-1a"
  vpc_id                = aws_vpc.myvpc.id
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-ap-south-1a"
  }
}

# Public Subnet in ap-south-1b
resource "aws_subnet" "public_subnet_ap_south_1b" {
  cidr_block            = "10.0.3.0/24"
  availability_zone     = "ap-south-1b"
  vpc_id                = aws_vpc.myvpc.id
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-ap-south-1b"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.myvpc.id
  tags = {
    Name = "my-igw"
  }
}

# Allocate an Elastic IP for the NAT Gateway
resource "aws_eip" "nat_eip" {
  vpc = true

  tags = {
    Name = "nat-eip"
  }
}

# Create a NAT Gateway in the public subnet
resource "aws_nat_gateway" "my_nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_ap_south_1a.id

  tags = {
    Name = "my-nat-gateway"
  }
}

# Create a route table for the private subnet
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.my_nat_gateway.id
  }

  tags = {
    Name = "private-route-table"
  }
}

# Associate the private subnet with the route table
resource "aws_route_table_association" "private_subnet_route_association" {
  route_table_id = aws_route_table.private_route_table.id
  subnet_id      = aws_subnet.private_subnet_ap_south_1a.id
}


# Route Table
resource "aws_route_table" "my_rt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "main-route-table"
  }
}

# Associate Route Table with Public Subnet in ap-south-1a
resource "aws_route_table_association" "public_sub_a" {
  route_table_id = aws_route_table.my_rt.id
  subnet_id      = aws_subnet.public_subnet_ap_south_1a.id
}

# Associate Route Table with Public Subnet in ap-south-1b
resource "aws_route_table_association" "public_sub_b" {
  route_table_id = aws_route_table.my_rt.id
  subnet_id      = aws_subnet.public_subnet_ap_south_1b.id
}

# Security Group for Load Balancer
resource "aws_security_group" "lb_sg" {
  vpc_id = aws_vpc.myvpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "load-balancer-sg"
  }
}

# Security Group for EC2 Instance
resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.myvpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    security_groups  = [aws_security_group.lb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-instance-sg"
  }
}

resource "aws_launch_template" "ec2_template" {
  name          = "ec2-launch-template"
  image_id      = "ami-053b12d3152c0cc71"  # Ensure this AMI ID is correct for your region
  instance_type = "t2.micro"
  key_name      = "secret"

  network_interfaces {
    security_groups = [aws_security_group.ec2_sg.id]  # Ensure this resource exists
    subnet_id       = aws_subnet.private_subnet_ap_south_1a.id  # Ensure this subnet exists
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash

              # Update the package list
              sudo apt update -y

              # Install Apache
              sudo apt install -y apache2

              # Start the Apache service
              sudo systemctl start apache2

              # Enable Apache to start on boot
              sudo systemctl enable apache2

              # Get the hostname of the EC2 instance
              HOSTNAME=$(hostname)

              # Create an HTML file that displays the instance's hostname
              echo "<html>
              <head>
                  <title>EC2 Instance</title>
              </head>
              <body>
                  <h1>Welcome to your EC2 Instance!</h1>
                  <p>Your hostname is: \$HOSTNAME</p>  # Escape the variable with a backslash
              </body>
              </html>" | sudo tee /var/www/html/index.html > /dev/null
            EOF
  )

  tags = {
    Name = "ec2-instance"
  }
}




resource "aws_autoscaling_group" "ec2_asg" {
  desired_capacity = 2
  max_size         = 3
  min_size         = 1
  health_check_type = "ELB" # Ensures ASG relies on ELB health checks
  health_check_grace_period = 300 # Adjust the grace period as needed

  launch_template {
    id      = aws_launch_template.ec2_template.id
    version = "$Latest"
  }

  vpc_zone_identifier = [aws_subnet.private_subnet_ap_south_1a.id]

  tag {
    key                 = "Name"
    value               = "ec2-instance"
    propagate_at_launch = true
  }
}


# Load Balancer
resource "aws_lb" "main_lb" {
  name               = "main-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.public_subnet_ap_south_1a.id, aws_subnet.public_subnet_ap_south_1b.id]

  tags = {
    Name = "main-load-balancer"
  }
}

# Target Group
resource "aws_lb_target_group" "ec2_target_group" {
  name     = "ec2-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id

  health_check {
    path     = "/"
    port     = "80"
    protocol = "HTTP"
  }

  tags = {
    Name = "ec2-target-group"
  }
}

# Listener for Load Balancer
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.main_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ec2_target_group.arn
  }
}

# Attach Auto Scaling Group to Target Group
resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.ec2_asg.id
  lb_target_group_arn = aws_lb_target_group.ec2_target_group.arn
}

