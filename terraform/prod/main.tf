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
