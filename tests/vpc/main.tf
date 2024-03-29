module "vpc" {
  source = "../../modules/vpc/v1"

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

module "vpc-sg" {
  source = "../../modules/sg/vpc/v1"

  profile      = var.profile
  project-name = var.project-name
  env          = var.env
  vpc-id       = module.vpc.vpc-id
  region       = var.region
}