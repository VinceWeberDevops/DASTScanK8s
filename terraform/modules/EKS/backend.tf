terraform {
  backend "s3" {
    bucket         = "dast-scan-terraform-state"
    key            = "terraform/eks/terraform.tfstate"
    region         = "eu-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}