# store the terraform state file in s3
terraform {
  backend "s3" {
    bucket  = "terraform-remote-state-tests"
    key     = "test-ec2.tfstate"
    region  = "us-east-1"
    profile = "devwithrico"
  }
}