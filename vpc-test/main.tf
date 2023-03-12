provider "aws" {
  region  = var.region
  profile = var.profile
}

# Create the vpc
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc-cidr
  tags       = {
    Name = "${var.project-name}-vpc"
  }
}

# Create the internet gateway and attach it to the vpc
resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.vpc.id
  tags   = {
    Name = "${var.project-name}-igw"
  }
}

# Return all availability zones in the region
data "aws_availability_zones" "available-zones" {}

# Create the public subnet A
resource "aws_subnet" "public-subnet-a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public-subnet-a-cidr
  availability_zone       = data.aws_availability_zones.available-zones.names[0]
  map_public_ip_on_launch = true
  tags                    = {
    Name = "${var.project-name}-public-subnet-a"
  }
}

# Create the public subnet B
resource "aws_subnet" "public-subnet-b" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public-subnet-b-cidr
  availability_zone       = data.aws_availability_zones.available-zones.names[1]
  map_public_ip_on_launch = true
  tags                    = {
    Name = "${var.project-name}-public-subnet-b"
  }
}

# Create the private subnet A
resource "aws_subnet" "private-subnet-a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.private-subnet-a-cidr
  availability_zone       = data.aws_availability_zones.available-zones.names[0]
  map_public_ip_on_launch = false
  tags                    = {
    Name = "${var.project-name}-private-subnet-a"
  }
}

# Create the private subnet B
resource "aws_subnet" "private-subnet-b" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.private-subnet-b-cidr
  availability_zone       = data.aws_availability_zones.available-zones.names[1]
  map_public_ip_on_launch = false
  tags                    = {
    Name = "${var.project-name}-private-subnet-b"
  }
}

# Create the public route table and add access to the internet gateway
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gateway.id
  }
  tags = {
    Name = "${var.project-name}-public-route-table"
  }
}

# Create the private route table
resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gateway.id
  }
  tags = {
    Name = "${var.project-name}-private-route-table"
  }
}

# Create all associations
resource "aws_route_table_association" "public-subnet-route-table-association-a" {
  subnet_id      = aws_subnet.public-subnet-a.id
  route_table_id = aws_route_table.public-route-table.id
}

resource "aws_route_table_association" "public-subnet-route-table-association-b" {
  subnet_id      = aws_subnet.public-subnet-b.id
  route_table_id = aws_route_table.public-route-table.id
}

resource "aws_route_table_association" "private-subnet-route-table-association-a" {
  subnet_id      = aws_subnet.private-subnet-a.id
  route_table_id = aws_route_table.private-route-table.id
}

resource "aws_route_table_association" "private-subnet-route-table-association-b" {
  subnet_id      = aws_subnet.private-subnet-b.id
  route_table_id = aws_route_table.private-route-table.id
}

# Create the elastic ip
resource "aws_eip" "elastic-ip" {
  vpc  = true
  tags = {
    Name = "${var.project-name}-eip"
  }
}

# Create the nat gateway
resource "aws_nat_gateway" "nat-gateway" {
  allocation_id = aws_eip.elastic-ip.id
  subnet_id     = aws_subnet.public-subnet-a.id
  depends_on    = [aws_internet_gateway.internet-gateway]
  tags          = {
    Name = "${var.project-name}-nat-gateway"
  }
}