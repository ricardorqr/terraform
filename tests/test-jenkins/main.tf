provider "aws" {
  region  = var.region
  profile = var.profile
  default_tags {
    tags = {
      "automation" = "terraform"
      "project"    = var.project-name
      "env"        = "dev"
    }
  }
}

# All created vpcs
data "aws_vpcs" "all-vpcs" {
  tags = {
    Name = var.vpc-name
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
  name   = "${var.project-name}-sg"
  vpc_id = data.aws_vpcs.all-vpcs.ids[0]
  ingress {
    description = "ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "http proxy access"
    from_port   = 8080
    to_port     = 8080
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
    Name = "${var.project-name}-sg"
  }
}

# Create the EC2 instance
resource "aws_instance" "ec2-instance" {
  ami                    = "ami-005f9685cb30f234b"
  instance_type          = "t2.micro"
  subnet_id              = data.aws_subnets.all-subnets.ids[0]
  vpc_security_group_ids = [aws_security_group.security-group.id]
  key_name               = var.key-name
  tags                   = {
    Name = var.project-name
  }
}

# Copy install-jenkins.sh and AWS credential to run after the instance is ready
resource "null_resource" "ansible" {
  # SSH into the ec2 instance
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/Downloads/devwithrico.pem")
    host        = aws_instance.ec2-instance.public_ip
  }
  # Copy the AWS credential
  provisioner "file" {
    source      = ".aws"
    destination = "/home/ec2-user/.aws"
  }
  # Copy the install-jenkins.sh
  provisioner "file" {
    source      = "install-jenkins.sh"
    destination = "/home/ec2-user/install-jenkins.sh"
  }
  # Execute the shell script commands
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /home/ec2-user/install-jenkins.sh",
      "sh /home/ec2-user/install-jenkins.sh",
      "aws eks update-kubeconfig --name test-eks --kubeconfig ~/.kube/config",
      "sudo cp -r /home/ec2-user/.aws /home/jenkins/.aws",
    ]
  }
  # Wait for ec2 to be created
  depends_on = [aws_instance.ec2-instance]
}

# Print the Jenkins url
output "website_url" {
  value = join("", ["http://", aws_instance.ec2-instance.public_dns, ":", "8080"])
}