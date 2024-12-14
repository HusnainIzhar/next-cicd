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

# Update the package manager
sudo apt-get update -y

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Nginx
sudo apt-get install -y nginx

# Variables
SECRET_NAME="token"
REPO_URL="https://github.com/HusnainIzhar/next-cicd.git"
APP_DIR="/home/ubuntu/app"

# Fetch the GitHub token from AWS Secrets Manager
GITHUB_TOKEN=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query SecretString --output text | jq -r '.token')

# Ensure the app directory exists
mkdir -p $APP_DIR
cd /home/ubuntu/app/next-cicd/my-app

# Clone the repository
if [ -d "next-cicd" ]; then
  echo "Repository already exists. Pulling latest changes..."
  cd next-cicd
  git reset --hard
  git pull origin main
else
  echo "Cloning the repository..."
  git clone https://$GITHUB_TOKEN@github.com/HusnainIzhar/next-cicd.git
  cd next-cicd
fi

# Navigate to the app directory
cd my-app

# Install dependencies
npm install

# Build the app
npm run build

# Install PM2 globally
sudo npm install -g pm2

# Restart the app with PM2
pm2 delete all
pm2 start npm --name "nextjs-app" -- start

# Configure Nginx
sudo bash -c 'cat > /etc/nginx/sites-available/default <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF'

# Restart Nginx to apply the configuration
sudo systemctl restart nginx
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