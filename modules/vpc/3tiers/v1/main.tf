#######
## VPC
#######

provider "aws" {
  region  = var.region
  profile = var.profile
  default_tags {
    tags = {
      automation = "terraform"
      project    = var.project-name
      env        = var.env
    }
  }
}

# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.1"

  name                                                         = var.project-name
  cidr                                                         = var.vpc-cidr
  azs                                                          = var.azs
  private_subnets                                              = var.private-subnet-cidrs
  public_subnets                                               = var.public-subnet-cidrs
  database_subnets                                             = var.database-subnet-cidrs
  enable_nat_gateway                                           = true
  single_nat_gateway                                           = false
  one_nat_gateway_per_az                                       = false
  enable_dns_hostnames                                         = true
  enable_dns_support                                           = true
  create_database_subnet_route_table                           = true
  public_subnet_suffix                                         = "public-subnet"
  private_subnet_suffix                                        = "private-subnet"
  database_subnet_suffix                                       = "database-subnet"
  public_subnet_enable_dns64                                   = true
  public_subnet_enable_resource_name_dns_a_record_on_launch    = true
  public_subnet_enable_resource_name_dns_aaaa_record_on_launch = true
  map_public_ip_on_launch                                      = true

  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = 1
    "kubernetes.io/cluster/${var.project-name}" = "owned"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = 1
    "kubernetes.io/cluster/${var.project-name}" = "owned"
    "karpenter.sh/discovery"                    = var.project-name
  }
}