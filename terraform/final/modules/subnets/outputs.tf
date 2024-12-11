output "private_subnet_id" {
  value = aws_subnet.private_subnet_ap_south_1a.id
}

output "public_subnet_ids" {
  value = [aws_subnet.public_subnet_ap_south_1a.id, aws_subnet.public_subnet_ap_south_1b.id]
}