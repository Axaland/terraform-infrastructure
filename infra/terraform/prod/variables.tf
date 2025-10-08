variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "env_name" {
  type    = string
  default = "prod"
}

variable "vpc_cidr" {
  type    = string
  default = "10.30.0.0/16"
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.30.1.0/24", "10.30.2.0/24"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.30.101.0/24", "10.30.102.0/24"]
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_user" {
  type    = string
  default = "app"
}

variable "service_image" {
  type    = string
  default = ""
}

variable "service_ecr_repository" {
  type    = string
  default = "app"
}

variable "service_image_tag" {
  type    = string
  default = "latest"
}

variable "monthly_budget_amount" {
  type    = number
  default = 2500
}

variable "budget_alert_emails" {
  type = list(string)
  default = [
    "finops@example.com",
    "security@example.com",
    "cto@example.com"
  ]
}

variable "waf_rate_limit" {
  type    = number
  default = 1000
}

variable "rds_allowed_cidrs" {
  type    = list(string)
  default = ["10.30.0.0/16"]
}

variable "enable_nat" {
  type    = bool
  default = false
}

variable "enable_guardduty" {
  type    = bool
  default = false
}

variable "enable_config" {
  type    = bool
  default = false
}
