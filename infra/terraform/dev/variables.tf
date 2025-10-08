variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "env_name" {
  type    = string
  default = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.10.1.0/24", "10.10.2.0/24"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.10.101.0/24", "10.10.102.0/24"]
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
  default = "000000000000.dkr.ecr.eu-west-1.amazonaws.com/app:latest"
}

variable "monthly_budget_amount" {
  type    = number
  default = 200
}

variable "budget_alert_emails" {
  type    = list(string)
  default = ["finops@example.com"]
}

variable "waf_rate_limit" {
  type    = number
  default = 1500
}

variable "rds_allowed_cidrs" {
  type    = list(string)
  default = ["10.10.0.0/16"]
}

variable "enable_nat" {
  type    = bool
  default = false
}

variable "enable_guardduty" {
  type    = bool
  default = false
}
