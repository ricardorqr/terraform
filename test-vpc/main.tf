module "vpc" {
  source = "../modules/vpc/3tiers/v1"

  profile               = var.profile
  project-name          = var.project-name
  env                   = var.env
  vpc-cidr              = var.vpc-cidr
  region                = var.region
  azs                   = var.azs
  public-subnet-cidrs   = var.public-subnet-cidrs
  private-subnet-cidrs  = var.private-subnet-cidrs
  database-subnet-cidrs = var.database-subnet-cidrs
}