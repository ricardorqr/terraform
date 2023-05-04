profile      = "devwithrico"
project-name = "vpc-test"
env          = "dev"

# https://www.fryguy.net/wp-content/tools/subnets.html
region                = "us-east-1"
azs                   = ["us-east-1a", "us-east-1b", "us-east-1c"]
vpc-cidr              = "10.0.0.0/21"
public-subnet-cidrs   = ["10.0.0.0/25", "10.0.0.128/25", "10.0.1.0/25"]
private-subnet-cidrs  = ["10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]
database-subnet-cidrs = ["10.0.5.0/24", "10.0.6.0/24", "10.0.7.0/24"]
