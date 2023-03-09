provider "aws" {
  region  = var.region
  profile = var.profile
}

# All created vpcs
data "aws_vpcs" "all-vpcs" {
  tags = {
    Name = var.vpc-name
  }
}

# All created key pairs
data "aws_key_pair" "all-keys" {
  tags = {
    Name = var.key-name
  }
}

# All created subnets
data "aws_subnets" "all-subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpcs.all-vpcs.ids[0]]
  }
  tags = {
    Name = var.subnet-name
  }
}

# Create the security group to allow incoming SSH traffic
resource "aws_security_group" "security-group" {
  name   = "test-sg"
  vpc_id = data.aws_vpcs.all-vpcs.ids[0]
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "test-sg"
  }
}

# Create the EC2 instance
resource "aws_instance" "ec2-instance" {
  ami                    = "ami-0c94855ba95c71c99"
  instance_type          = "t2.micro"
  subnet_id              = data.aws_subnets.all-subnets.ids[0]
  vpc_security_group_ids = [aws_security_group.security-group.id]
  key_name               = data.aws_key_pair.all-keys.key_name
  tags                   = {
    Name = "test-ec2"
  }
}