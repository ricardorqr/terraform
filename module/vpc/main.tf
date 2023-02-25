# create the vpc
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc-cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project-name}-vpc"
    env  = var.env
  }
}

# create the internet gateway and attach it to vpc
resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project-name}-igw"
    env  = var.env
  }
}

# use data source to get all availability zones in the region
data "aws_availability_zones" "available-zones" {}

# create the public subnet A
resource "aws_subnet" "public-subnet-a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public-subnet-a-cidr
  availability_zone       = data.aws_availability_zones.available-zones.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-a"
  }
}

## create public subnet az2
#resource "aws_subnet" "public_subnet_az2" {
#vpc_id                  =
#cidr_block              =
#availability_zone       =
#map_public_ip_on_launch =
#
#tags      = {
#Name    =
#}
#}

# create the public route table A and add access to the internet gateway
resource "aws_route_table" "public-route-table-a" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gateway.id
  }

  tags = {
    Name = "${var.project-name}-public-route-table-a"
    env  = var.env
  }
}

# associate the public subnet A to the public route table A
resource "aws_route_table_association" "public-subnet-rute-table-a-association" {
  subnet_id      = aws_subnet.public-subnet-a.id
  route_table_id = aws_route_table.public-route-table-a.id
}

## associate public subnet az2 to "public route table"
#resource "aws_route_table_association" "public_subnet_az2_route_table_association" {
#subnet_id           =
#route_table_id      =
#}

# create the private subnet A
resource "aws_subnet" "private-subnet-a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.private-subnet-a-cidr
  availability_zone       = data.aws_availability_zones.available-zones.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-a"
  }
}

## create private app subnet az2
#resource "aws_subnet" "private_app_subnet_az2" {
#vpc_id                   =
#cidr_block               =
#availability_zone        =
#map_public_ip_on_launch  =
#
#tags      = {
#Name    =
#}
#}

## create private data subnet az1
#resource "aws_subnet" "private_data_subnet_az1" {
#vpc_id                   =
#cidr_block               =
#availability_zone        =
#map_public_ip_on_launch  =
#
#tags      = {
#Name    =
#}
#}
#
## create private data subnet az2
#resource "aws_subnet" "private_data_subnet_az2" {
#vpc_id                   =
#cidr_block               =
#availability_zone        =
#map_public_ip_on_launch  =
#
#tags      = {
#Name    =
#}
#}