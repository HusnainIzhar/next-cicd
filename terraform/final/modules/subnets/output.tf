output "private_subnet_us_east_1a_id" {
  value = aws_subnet.private_subnet_us_east_1a.id
}

output "public_subnet_us_east_1a_id" {
  value = aws_subnet.public_subnet_us_east_1a.id
  
}

output "public_subnet_us_east_1b_id" {
  value = aws_subnet.public_subnet_us_east_1b.id  
  
}