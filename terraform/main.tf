provider "aws" {
  region = "ap-south-1"
}

resource "aws_instance" "example" {
  ami           = "ami-053b12d3152c0cc71"  # Replace with your correct AMI ID
  instance_type = "t2.micro"
  key_name      = "test"  # Ensure this key pair exists in your region

  tags = {
    Name = "example-instance"
  }

