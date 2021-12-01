provider "aws" {
   	profile = "${var.aws_profile}"
	region = "${var.aws_region_ec2}"
}
terraform {
  backend "s3" {
    bucket = "second-scripst-321"
    key    = "terraform_intro/ec2_instance/instance"
    region = "us-east-1"
  }
required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
 }
 required_version = ">= 0.14.9"
}
