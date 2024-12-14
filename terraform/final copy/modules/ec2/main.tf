resource "aws_launch_template" "ec2_template" {
  name          = "${var.project_name}-launch-template"
  image_id      = var.template_var.image_id
  instance_type = var.template_var.instance_type
  key_name      = var.template_var.key_name

  monitoring {
    enabled = true
  }

  network_interfaces {
    security_groups = [var.sg_ec2]
    associate_public_ip_address = false
  }

  user_data = base64encode(templatefile("${path.module}/user-data.tpl"))

  tags = {
    Name = "${var.project_name}-ec2-instance"
  }
}
