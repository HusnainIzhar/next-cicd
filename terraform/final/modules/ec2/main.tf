variable "vpc_id" {
  type = string
}

variable "private_subnet_id" {
  type = string
}

variable "security_group_id" {
  type = string
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
    security_groups = [var.security_group_id]
    subnet_id       = var.private_subnet_id
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
                  <h1>Welcome to my EC2!</h1>
                  <p>my hostname is: \$${HOSTNAME}</p>
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

  vpc_zone_identifier = [var.private_subnet_id]

  tag {
    key                 = "Name"
    value               = "ec2-instance"
    propagate_at_launch = true
  }
}

resource "aws_lb_target_group" "ec2_target_group" {
  name     = "ec2-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path     = "/"
    port     = "80"
    protocol = "HTTP"
  }

  tags = {
    Name = "ec2-target-group"
  }
}

output "target_group_arn" {
  value = aws_lb_target_group.ec2_target_group.arn
}