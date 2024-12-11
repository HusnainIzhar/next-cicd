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
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "myvpc"
  }
}

# Request an ACM Certificate
resource "aws_acm_certificate" "mycert_acm" {
  domain_name               = "ec2.${aws_lb.my_alb.dns_name}"
  subject_alternative_names = ["*.ec2.${aws_lb.my_alb.dns_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Create Route 53 DNS Record for Validation
data "aws_route53_zone" "selected_zone" {
  name         = "mydomain.com"  # Replace with your domain name
  private_zone = false
}

resource "aws_route53_record" "cert_validation_record" {
  for_each = {
    for dvo in aws_acm_certificate.mycert_acm.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.selected_zone.zone_id
}

# Handle Certificate Validation
resource "aws_acm_certificate_validation" "cert_validation" {
  timeouts {
    create = "5m"
  }
  certificate_arn         = aws_acm_certificate.mycert_acm.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_record : record.fqdn]
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
  domain = "vpc"
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

# Route Table for Public Subnets
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
  monitoring {
    enabled = true
  }

  network_interfaces {
    security_groups = [aws_security_group.ec2_sg.id]
    subnet_id       = aws_subnet.private_subnet_ap_south_1a.id
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
                  <p>Your hostname is: \$HOSTNAME</p>
              </body>
              </html>" | sudo tee /var/www/html/index.html > /dev/null
            EOF
  )

  tags = {
    Name = "ec2-instance"
  }
}

resource "aws_autoscaling_group" "ec2_asg" {
  desired_capacity          = 2
  max_size                  = 3
  min_size                  = 1
  health_check_type         = "ELB"
  health_check_grace_period = 300

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

# Application Load Balancer (ALB)
resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.public_subnet_ap_south_1a.id, aws_subnet.public_subnet_ap_south_1b.id]
  enable_deletion_protection = false
  tags = {
    Name = "my-alb"
  }
}

# Security group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Allow HTTP traffic to the ALB"
  vpc_id      = aws_vpc.myvpc.id

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
    Name = "alb-sg"
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
  load_balancer_arn = aws_lb.my_alb.arn
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
  lb_target_group_arn    = aws_lb_target_group.ec2_target_group.arn
}

# Output Load Balancer DNS
output "load_balancer_dns" {
  value = aws_lb.my_alb.dns_name
}