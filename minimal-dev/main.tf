terraform {
  backend "s3" {
    bucket         = "tfstate-terraform-infrastructure-eu-west-1"
    key            = "dev/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "tf-lock-terraform-infrastructure"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
  default_tags {
    tags = {
      Environment = "dev"
      Project     = "terraform-infrastructure"
      ManagedBy   = "terraform"
    }
  }
}

# IAM role per GitHub OIDC
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "github_ci" {
  name = "github-ci-role-dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:AXALAND/terraform-infrastructure:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_ci_admin" {
  role       = aws_iam_role.github_ci.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "random_id" "suffix" {
  byte_length = 4
}

# Bucket di test
resource "aws_s3_bucket" "test" {
  bucket = "test-deploy-dev-${random_id.suffix.hex}"
}

output "ci_role_arn" {
  value = aws_iam_role.github_ci.arn
}

output "test_bucket" {
  value = aws_s3_bucket.test.bucket
}