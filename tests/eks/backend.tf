# store the terraform state file in s3
terraform {
  backend "s3" {
    bucket  = "devwithrico-terraform-remote-state"
    key     = "terraform/tests/eks/eks-karpenter-vpc.tfstate"
    region  = "us-east-1"
    profile = "devwithrico"
  }
}