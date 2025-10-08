terraform {
  backend "s3" {
    bucket         = "tfstate-terraform-infrastructure-eu-west-1"
    key            = "env/prod/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "tf-lock-terraform-infrastructure"
    encrypt        = true
  }
}