provider "aws" {
  region  = var.region
  profile = var.profile
}

# create the vpc
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc-cidr # "10.0.0.0/16"
  tags       = {
    Name = "${var.project-name}-vpc"
  }
}

# create the internet gateway and attach it to the vpc
resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.vpc.id
  tags   = {
    Name = "${var.project-name}-igw"
  }
}

# create the public route table A and add access to the internet gateway
resource "aws_route_table" "public-route-table-a" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gateway.id
  }
  tags = {
    Name = "${var.project-name}-public-route-table-a"
  }
}

# create the private route table A
resource "aws_route_table" "private-route-table-a" {
  vpc_id = aws_vpc.vpc.id
  tags   = {
    Name = "${var.project-name}-private-route-table-a"
  }
}

# all availability zones in the region
data "aws_availability_zones" "available-zones" {}

# create the public subnet
resource "aws_subnet" "public-subnet-a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public-subnet-a-cidr # "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available-zones.names[0] # us-east-1a
  tags              = {
    Name = "${var.project-name}-public-subnet-a"
  }
}

# create the private subnet
resource "aws_subnet" "private-subnet-a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private-subnet-a-cidr # "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available-zones.names[0] # us-east-1a
  tags              = {
    Name = "${var.project-name}-private-subnet-a"
  }
}

resource "aws_route_table_association" "public-subnet-route-table-a-association" {
  subnet_id      = aws_subnet.public-subnet-a.id
  route_table_id = aws_route_table.public-route-table-a.id
}

resource "aws_route_table_association" "private-subnet-route-table-a-association" {
  subnet_id      = aws_subnet.private-subnet-a.id
  route_table_id = aws_route_table.private-route-table-a.id
}

# create the elastic ip
resource "aws_eip" "elastic-ip" {
  vpc = true
  tags              = {
    Name = "${var.project-name}-eip"
  }
}

# create the nat gateway
resource "aws_nat_gateway" "nat-gateway" {
  allocation_id = aws_eip.elastic-ip.id
  subnet_id     = aws_subnet.public-subnet-a.id
  tags          = {
    Name = "${var.project-name}-nat-gateway"
  }
}

# create the route to the nat gateway
resource "aws_route" "nat-gateway-route" {
  route_table_id         = aws_route_table.private-route-table-a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat-gateway.id
}