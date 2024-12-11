output "load_balancer_dns" {
  value = aws_lb.my_alb.dns_name
}