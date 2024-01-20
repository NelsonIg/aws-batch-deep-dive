terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
  default_tags {
    tags = {
      "project" = "aws-batch-deep-dive"
    }
  }
}

module "batch_deep_dive" {
    source = "./modules/batch_deep_dive"
    
    prefix = var.prefix
    security_group_ids = [aws_security_group.this.id]
    subnet_ids = var.subnet_ids
    bucket_name = aws_s3_bucket.this.id
}

resource "aws_security_group" "this" {
  name_prefix = var.prefix
  vpc_id = var.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "this" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port = 443
  to_port = 443
}

resource "aws_s3_bucket" "this" {
  bucket = "${var.prefix}-batch-deep-dive"
  force_destroy = true
}