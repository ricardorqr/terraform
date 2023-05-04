#profile      = "devwithrico"
profile      = "vdmdevops"
project-name = "vpc-test-rico"
env          = "dev"

# https://www.fryguy.net/wp-content/tools/subnets.html
#region                = "us-west-1"
#azs                   = ["us-west-1b", "us-west-1c"]
#vpc-cidr              = "10.0.0.0/21"
#public-subnet-cidrs   = ["10.0.0.0/25", "10.0.0.128/25"]
#private-subnet-cidrs  = ["10.0.2.0/24", "10.0.3.0/24"]
#database-subnet-cidrs = []

region                = "us-west-2"
azs                   = ["us-west-2a", "us-west-2b", "us-west-2c"]
vpc-cidr              = "10.0.0.0/21"
public-subnet-cidrs   = ["10.0.0.0/25", "10.0.0.128/25", "10.0.1.0/25"]
private-subnet-cidrs  = ["10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]
database-subnet-cidrs = ["10.0.5.0/24", "10.0.6.0/24", "10.0.7.0/24"]
