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

# AWS Provider
provider "aws" {
  region = "us-east-1"
}

# S3 bucket for remote state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-0lnx9"
}

# Enable S3 versioning
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
  enable_dns_support = true

  tags = {
    Name = "ymir"
  }
}

##################
###### DNS #######
##################

# Route53 aws.local DNS Zone
resource "aws_route53_zone" "internal"{
  name = "aws.local"

  vpc {
    vpc_id = aws_vpc.ymir.id
  }
}

# Odin Control 1 DNS
resource "aws_route53_record" "odin_control_1_dns"{
  zone_id = aws_route53_zone.internal.id
  name = "odincontrol1.aws.local"
  type = "A"
  ttl = 300
  records = [aws_instance.odin_control_1.private_ip]
}

##################
### NETWORKING ###
##################

# Internet Gateway
resource "aws_internet_gateway" "ig1" {
  vpc_id = aws_vpc.ymir.id
  
  tags = {
    Name = "ig1"
  }
}

# Odin Talos Public Subnet 01
resource "aws_subnet" "public_1a" {
  vpc_id = aws_vpc.ymir.id
  cidr_block = "10.88.4.0/22"
  availability_zone = "us-east-1a"
  
  tags = {
    Name = "public_1a"
  }
}

# Odin Talos Public Subnet 02
resource "aws_subnet" "public_1b" {
  vpc_id = aws_vpc.ymir.id
  cidr_block = "10.88.8.0/22"
  availability_zone = "us-east-1b"
  
  tags = {
    Name = "public_1b"
  }
}

# Odin Talos Public Subnet 03
resource "aws_subnet" "public_1c" {
  vpc_id = aws_vpc.ymir.id
  cidr_block = "10.88.12.0/22"
  availability_zone = "us-east-1c"

  tags = {
    Name = "public_1c"
  }
}

# Odin Talos Private Subnet 01
resource "aws_subnet" "private_1a" {
  vpc_id = aws_vpc.ymir.id
  cidr_block = "10.88.16.0/22"
  availability_zone = "us-east-1a"
  
  tags = {
    Name = "private_1a"
  }
}

# Odin Talos Private Subnet 02
resource "aws_subnet" "private_1b" {
  vpc_id = aws_vpc.ymir.id
  cidr_block = "10.88.20.0/22"
  availability_zone = "us-east-1b"
  
  tags = {
    Name = "private_1b"
  }
}

# Odin Talos Private Subnet 03
resource "aws_subnet" "private_1c" {
  vpc_id = aws_vpc.ymir.id
  cidr_block = "10.88.44.0/22"
  availability_zone = "us-east-1c"
  
  tags = {
    Name = "private_1c"
  }
}

##################
### INSTANCES ####
##################

# EC2 Odin Talos Control 01
resource "aws_instance" "odin_control_1" {
  ami = "ami-04b014737d71581d4"
  availability_zone = "us-east-1a"
  instance_type = "t4g.nano"
  subnet_id = aws_subnet.private_1a.id
  associate_public_ip_address = false

  private_dns_name_options {
    enable_resource_name_dns_a_record = true
    hostname_type = "resource-name"
  }

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

# EC2 Odin Talos Control 02
#resource "aws_instance" "odin_control_2" {
#  ami = "ami-04b014737d71581d4"
#  availability_zone = "us-east-1a"
#  instance_type = "t4g.nano"
#  subnet_id = aws_subnet.private_1a.id
#  associate_public_ip_address = false
#
#  root_block_device {
#    volume_type = "gp3"
#    volume_size = 20
#    iops = 3000
#    delete_on_termination = true
#    encrypted = true
#  }
#  tags = {
#    Name = "odin_control_2"
#  }
#}

# EC2 Odin Talos Control 03
#resource "aws_instance" "odin_control_3" {
#  ami = "ami-04b014737d71581d4"
#  availability_zone = "us-east-1a"
#  instance_type = "t4g.nano"
#  subnet_id = aws_subnet.private_1a.id
#  associate_public_ip_address = false
#
#  root_block_device {
#    volume_type = "gp3"
#    volume_size = 20
#    iops = 3000
#    delete_on_termination = true
#    encrypted = true
#    }
#
#    tags = {
#    Name = "odin_control_3"
#    }
#}

# EC2 VyOS 01 w/ self-generated AMI
resource "aws_instance" "vyos_1" {
  ami = "ami-0ec8fc8f9bd949179"
  availability_zone = "us-east-1a"
  instance_type = "t3.micro"
  subnet_id = aws_subnet.public_1a.id
  associate_public_ip_address = true
  source_dest_check = false

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

