# Auto Scaling Group
resource "aws_autoscaling_group" "ec2_asg" {
  desired_capacity          = var.ec2_asg_var.desired_capacity
  max_size                  = var.ec2_asg_var.max_size
  min_size                  = var.ec2_asg_var.min_size
  target_group_arns         = [var.aws_lb_target_group]
  health_check_type         = "EC2"
  health_check_grace_period = var.ec2_asg_var.health_check_grace_period
  vpc_zone_identifier       = var.private_subnet

  launch_template {
    id      = var.ec2_template_launch_id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "${var.project_name}-ec2-instance"
    propagate_at_launch = true
  }

 lifecycle {
    create_before_destroy = true
  }
  
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["launch_template"]
  }
}