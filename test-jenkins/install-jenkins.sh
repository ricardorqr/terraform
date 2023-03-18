#!/bin/bash

# Update package list
sudo yum upgrade -y


# Install utils
sudo amazon-linux-extras install epel -y
sudo yum install python3-pip
sudo amazon-linux-extras install java-openjdk11 -y
sudo yum install maven -y
sudo yum install git -y
sudo pip3 install ansible
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum install terraform -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
sudo curl -LO "https://dl.k8s.io/release/$(curl -LO https://dl.k8s.io/release/v1.25.0/bin/linux/amd64/kubectl)/bin/linux/amd64/kubectl"
sudo curl -LO "https://dl.k8s.io/$(curl -LO https://dl.k8s.io/release/v1.25.0/bin/linux/amd64/kubectl)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin


# Create Jenkins user
sudo useradd jenkins
echo -e 'jenkins\njenkins' | sudo passwd jenkins
echo 'jenkins ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/jenkins
sudo sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sudo systemctl restart sshd.service


# Install Jenkins
sudo yum upgrade -y
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
sudo yum upgrade -y
sudo yum install jenkins -y
sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo systemctl status jenkins


# Install Docker
sudo yum upgrade -y
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo systemctl status docker
sudo usermod -a -G docker ec2-user
sudo usermod -a -G docker jenkins
#newgrp docker


# Last update
sudo yum upgrade -y


# Check Installations
echo "=============== PIP3 ==============="
pip3 --version

echo "=============== Ansible ==============="
ansible --version

echo "=============== Maven ==============="
mvn --version

echo "=============== Git ==============="
git --version

echo "=============== Java ==============="
java --version

echo "=============== Terraform ==============="
terraform --version

echo "=============== AWSCLI ==============="
aws --version

echo "=============== Kubectl ==============="
kubectl version --client

echo "=============== EKSCTL ==============="
eksctl version

echo "=============== Docker Group ==============="
grep docker /etc/group

echo "=============== Jenkins Password ==============="
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
