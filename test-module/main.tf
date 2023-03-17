# configure aws provider
provider "aws" {
  region  = var.region
  profile = "stg-ext"
}

# create the VPC
module "vpc" {
  source                = "../module/vpc"
  region                = var.region
  project-name          = var.project-name
  env                   = var.env
  vpc-cidr              = var.vpc-cidr
  public-subnet-a-cidr  = var.public-subnet-a-cidr
  private-subnet-a-cidr = var.private-subnet-a-cidr
}