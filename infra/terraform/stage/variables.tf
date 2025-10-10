variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "env_name" {
  type    = string
  default = "stage"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.20.101.0/24", "10.20.102.0/24"]
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

variable "github_org" {
  type    = string
  default = "AXALAND"
}

variable "github_repo" {
  type    = string
  default = "terraform-infrastructure"
}

variable "monthly_budget_amount" {
  type    = number
  default = 600
}

variable "cost_anomaly_threshold" {
  type    = number
  default = 150
}

variable "budget_alert_emails" {
  type    = list(string)
  default = ["finops@example.com", "platform@example.com"]
}

variable "cost_anomaly_emails" {
  type    = list(string)
  default = ["finops@example.com", "platform@example.com"]
}

variable "cost_anomaly_forecast_threshold" {
  type    = number
  default = 200
}

variable "cost_anomaly_monitor_tags" {
  type = map(string)
  default = {
    Environment = "stage"
  }
}

variable "cost_anomaly_enable_forecast" {
  type    = bool
  default = true
}

variable "alert_emails" {
  type    = list(string)
  default = ["platform@example.com"]
}

variable "waf_rate_limit" {
  type    = number
  default = 1200
}

variable "rds_allowed_cidrs" {
  type    = list(string)
  default = ["10.20.0.0/16"]
}

variable "enable_nat" {
  type    = bool
  default = false
}

variable "enable_guardduty" {
  type    = bool
  default = true
}

variable "enable_config" {
  type    = bool
  default = true
}

variable "rds_rotation_interval_days" {
  type    = number
  default = 30
}

variable "config_notification_emails" {
  type    = list(string)
  default = ["platform@example.com"]
}

variable "healthcheck_schedule_expression" {
  type    = string
  default = "rate(5 minutes)"
}

variable "synthetic_timeout_seconds" {
  type    = number
  default = 60
}

variable "chatops_enabled" {
  type    = bool
  default = true
}

variable "enable_conformance_pack" {
  type    = bool
  default = true
}

variable "chatops_slack_team_id" {
  type    = string
  default = "T0123456789"
}

variable "chatops_slack_channel_id" {
  type    = string
  default = "C0123456789"
}

variable "chatops_iam_role_arn" {
  type    = string
  default = "arn:aws:iam::123456789012:role/AWSChatbot-Notifications"
}
