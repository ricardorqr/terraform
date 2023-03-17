# store the terraform state file in s3
terraform {
  backend "s3" {
    bucket  = "terraform-remote-state-tests"
    key     = "test-vpc.tfstate"
    region  = "us-east-1"
    profile = "devwithrico"
  }
}