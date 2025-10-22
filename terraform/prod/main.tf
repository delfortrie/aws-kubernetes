terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.17"
    }
  }

  backend "s3" {
    bucket         = "terraform-state-0lnx9"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}

# S3 bucket for remote state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-0lnx9"
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# VPC ymir
resource "aws_vpc" "ymir" {
  cidr_block = "10.88.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "ymir"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "ig1" {
  vpc_id = aws_vpc.ymir.id
  
  tags = {
    Name = "ig1"
  }
}

# Odin Talos Subnet 01
resource "aws_subnet" "public_1a" {
  vpc_id = aws_vpc.ymir.id
  cidr_block = "10.88.4.0/22"
  availability_zone = "us-east-1a"
  
  tags = {
    Name = "public_1a"
  }
}

# Odin Talos Subnet 02
resource "aws_subnet" "public_1b" {
  vpc_id = aws_vpc.ymir.id
  cidr_block = "10.88.8.0/22"
  availability_zone = "us-east-1b"
  
  tags = {
    Name = "public_1b"
  }
}

# Odin Talos Subnet 03
resource "aws_subnet" "public_1c" {
  vpc_id = aws_vpc.ymir.id
  cidr_block = "10.88.12.0/22"
  availability_zone = "us-east-1c"

  tags = {
    Name = "public_1c"
  }
}

# EC2 Odin Talos Control 01
resource "aws_instance" "odin_control_1" {
  ami = "ami-04b014737d71581d4"
  availability_zone = "us-east-1a"
  instance_type = "t4g.nano"
  subnet_id = aws_subnet.public_1a.id
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    iops = 3000
    delete_on_termination = true
    encrypted = true
  }

  tags = {
    Name = "odin_control_1"
  }
}

# EC2 VyOS 01
resource "aws_instance" "vyos_1" {
  ami = "ami-01be19d9d4f6d7eba"
  availability_zone = "us-east-1a"
  instance_type = "t3.micro"
  subnet_id = aws_subnet.public_1a.id
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 10
    iops = 3000
    delete_on_termination = true
    encrypted = true
  }

  tags = {
    Name = "vyos_1"
  }
}
