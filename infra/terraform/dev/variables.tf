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
  default = ""
}

variable "github_org" {
  type    = string
  default = "AXALAND"
}

variable "github_repo" {
  type    = string
  default = "terraform-infrastructure"
}

variable "service_image_tag" {
  type    = string
  default = "2430acc-amd64"
}

variable "monthly_budget_amount" {
  type    = number
  default = 200
}

variable "cost_anomaly_threshold" {
  type    = number
  default = 50
}

variable "budget_alert_emails" {
  type    = list(string)
  default = ["finops@example.com"]
}

variable "cost_anomaly_emails" {
  type    = list(string)
  default = ["finops@example.com"]
}

variable "cost_anomaly_forecast_threshold" {
  type    = number
  default = 75
}

variable "cost_anomaly_monitor_tags" {
  type = map(string)
  default = {
    Environment = "dev"
  }
}

variable "cost_anomaly_enable_forecast" {
  type    = bool
  default = true
}

variable "alert_emails" {
  type    = list(string)
  default = ["marco.papagni@libero.it"]
}

variable "config_notification_emails" {
  type    = list(string)
  default = ["marco.papagni@libero.it"]
}

variable "enable_conformance_pack" {
  type    = bool
  default = false
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
  default = true
}

variable "enable_guardduty" {
  type    = bool
  default = false
}

variable "backup_replica_region" {
  type    = string
  default = "eu-central-1"
}

variable "backup_replica_vault_name" {
  type    = string
  default = null
}

variable "healthcheck_schedule_expression" {
  type    = string
  default = "rate(5 minutes)"
}

variable "synthetic_timeout_seconds" {
  type    = number
  default = 60
}

variable "rds_rotation_interval_days" {
  type    = number
  default = 30
}
