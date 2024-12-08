terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.54.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
  }
  
  backend "s3" {
    bucket = "demo-bucket-9419a72476f569ef"
    key    = "backend.tfstate"
    region = "eu-north-1"
  }
}

provider "aws" {
  region = "eu-north-1"
}

resource "random_id" "rand_id" {
  byte_length = 8
}

resource "aws_s3_bucket" "app_bucket" {
  bucket = "app-bucket-${random_id.rand_id.hex}"
}

resource "aws_instance" "my_server" {
  ami           = "ami-0c0e147c706360bd7"
  instance_type = "t3.nano"

  tags = {
    Name = "SampleServer"
  }
}

output "random_id_value" {
  value = random_id.rand_id.hex
}
