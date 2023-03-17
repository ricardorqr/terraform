# store the terraform state file in s3
terraform {
  backend "s3" {
    bucket  = "terraform-remote-state-rico"
    key     = "module-test.tfstate"
    region  = "us-east-1"
    profile = "stg-ext"
  }
}