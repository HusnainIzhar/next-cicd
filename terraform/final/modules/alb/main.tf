# Application Load Balancer (ALB)
resource "aws_lb" "couro_web_alb" {
  name                        = "${var.project_name}-alb"
  internal                    = false
  load_balancer_type          = "application"
  security_groups             = [var.sg_alb] # ALB security group
  subnets                     = [var.public_subnet_us_east_1a,var.public_subnet_us_east_1b] # Public subnets
  enable_deletion_protection  = false

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# Target Group
resource "aws_lb_target_group" "ec2_target_group" {
  name     = "${var.project_name}-ec2-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path     = "/"
    port     = "80"
    protocol = "HTTP"
  }

  tags = {
    Name = "${var.project_name}-ec2-target-group"
  }
}

# Listener for Load Balancer
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.couro_web_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ec2_target_group.arn
  }
}
