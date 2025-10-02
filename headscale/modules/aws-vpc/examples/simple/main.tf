terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.57"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

module "simple" {
  source = "../.."

  cidr_block = "10.24.0.0/16"
  name       = "simple-vpc"
}
