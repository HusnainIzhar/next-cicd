output "sg_ec2" {
  value = aws_security_group.ec2_sg.id
}

output "sg_lb" {
    value = aws_security_group.lb_sg.id
  
}

output "sg_alb" {
  value = aws_security_group.alb_sg.id
  
}