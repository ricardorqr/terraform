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

# https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest
data "external" "current_ip" {
  program = ["bash", "-c", "curl -s 'https://api.ipify.org?format=json'"]
}

/*
"public-sg" exposes the EC2s to the internet.
Opened ports:
- http-80-tcp
- http-8080-tcp
- https-443-tcp
- ssh-tcp
*/

module "public-sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.2"

  name               = "${var.project-name}-public-subnet-sg"
  description        = "Allow access from public SG only"
  vpc_id             = var.vpc-id
  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]

  ingress_with_cidr_blocks = [
    {
      rule        = "http-80-tcp"
      description = "Open HTTP ports"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      rule        = "http-8080-tcp"
      description = "Open HTTP ports"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      rule        = "https-443-tcp"
      description = "Open HTTPS ports"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      rule        = "ssh-tcp"
      description = "Open SSH ports"
      cidr_blocks = "${data.external.current_ip.result.ip}/32"
    }
  ]
}

/*
"private-sg" is not exposed to the internet. It receives traffic ONLY from public-sg.
Opened ports:
- http-80-tcp
- http-8080-tcp
- https-443-tcp
- all-icmp (ping and etc)
- ssh-tcp (SSH from bastion server)
*/

module "private-sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.2"

  name                                                     = "${var.project-name}-private-subnet-sg"
  description                                              = "Allow access from public SG only"
  vpc_id                                                   = var.vpc-id
  egress_cidr_blocks                                       = ["0.0.0.0/0"]
  egress_rules                                             = ["all-all"]
  number_of_computed_ingress_with_source_security_group_id = 5  # This count should match the number of rules in "computed_ingress_with_source_security_group_id"

  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "http-80-tcp"
      description              = "Open HTTP ports"
      source_security_group_id = module.public-sg.security_group_id
    },
    {
      rule                     = "http-8080-tcp"
      description              = "Open HTTP ports"
      source_security_group_id = module.public-sg.security_group_id
    },
    {
      rule                     = "https-443-tcp"
      description              = "Open HTTPS ports"
      source_security_group_id = module.public-sg.security_group_id
    },
    {
      rule                     = "all-icmp"
      description              = "Open all IPV4 ICMP"
      source_security_group_id = module.public-sg.security_group_id
    },
    {
      rule                     = "ssh-tcp"
      description              = "Open SSH ports"
      source_security_group_id = module.public-sg.security_group_id
    }
  ]
}

/*
"database-sg" is not exposed to the internet. It receives traffic ONLY from private-sg.
Opened ports:
- mysql-tcp (Aurora DB)
*/
module "database-sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.2"

  name                                                     = "${var.project-name}-database-subnet-sg"
  description                                              = "Allow access from private SG only"
  vpc_id                                                   = var.vpc-id
  egress_cidr_blocks                                       = ["0.0.0.0/0"]
  egress_rules                                             = ["all-all"]
  number_of_computed_ingress_with_source_security_group_id = 1

  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "mysql-tcp"
      description              = "Open MYSQL/Aurora port"
      source_security_group_id = module.private-sg.security_group_id
    }
  ]
}
