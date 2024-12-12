# Auto Scaling Group
resource "aws_autoscaling_group" "ec2_asg" {
  desired_capacity          = var.ec2_asg_var.desired_capacity
  max_size                  = var.ec2_asg_var.max_size
  min_size                  = var.ec2_asg_var.min_size
  health_check_type         = "ELB"
  health_check_grace_period = var.ec2_asg_var.health_check_grace_period

  launch_template {
    id      = var.ec2_template_launch_id
    version = "$Latest"
  }

  # Use private subnets for the ASG
  vpc_zone_identifier = [
    aws_subnet.private_subnet_us_east_1a,
    aws_subnet.private_subnet_us_east_1b
  ]

  tag {
    key                 = "Name"
    value               = "${var.project_name}-ec2-instance"
    propagate_at_launch = true
  }
}

# Attach Auto Scaling Group to Target Group
resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.ec2_asg.name
  lb_target_group_arn    = aws_lb_target_group.ec2_target_group.arn
}
