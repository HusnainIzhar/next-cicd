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
    version = var.launch_template_latest_version
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
      instance_warmup        = 300
    }
  }
}

resource "aws_autoscaling_policy" "target_tracking_policy" {
  name                   = "TargetTrackingPolicy"
  autoscaling_group_name = aws_autoscaling_group.ec2_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_alarm" {
  alarm_name          = "${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors EC2 CPU utilization"
  alarm_actions       = []  # Optional: Add SNS topics or other actions
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ec2_asg.name
  }
}