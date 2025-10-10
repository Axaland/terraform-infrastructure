provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "backup_replica"
  region = var.aws_region
}