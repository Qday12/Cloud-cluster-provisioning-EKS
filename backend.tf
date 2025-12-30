terraform {
  backend "s3" {
    bucket         = "cluster-provisioning-2115-tfstate"
    key            = "eks/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}