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

  vpc_zone_identifier = [var.subnet_id]

  tag {
    key                 = "Name"
    value               = "ec2-instance"
    propagate_at_launch = true
  }
}