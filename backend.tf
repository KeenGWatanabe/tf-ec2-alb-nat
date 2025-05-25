terraform {
  backend "s3" {
    bucket         = "ce-grp-4.tfstate-backend.com"
    key            = "vpc2/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "ce-grp-4-terraform-state-locks"
    }
}