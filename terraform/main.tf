provider "aws" {
  region = "ap-south-1"
}

resource "aws_instance" "my_instance" {
  ami           = "ami-053b12d3152c0cc71"  # Replace with your correct AMI ID
  instance_type = "t2.micro"

  tags = {
    Name = "MYEC2"
  }
}
