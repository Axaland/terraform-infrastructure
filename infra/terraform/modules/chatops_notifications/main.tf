variable "env" {
  description = "Environment name"
  type        = string
}

variable "slack_channel_id" {
  description = "Slack channel ID (e.g. C123456)"
  type        = string
}

variable "slack_team_id" {
  description = "Slack team (workspace) ID configurato in AWS Chatbot"
  type        = string
}

variable "iam_role_arn" {
  description = "Role ARN autorizzato da AWS Chatbot a pubblicare sul canale"
  type        = string
}

variable "sns_topic_arns" {
  description = "List of SNS topic ARNs to connect to the ChatOps channel"
  type        = list(string)
}

variable "logging_level" {
  description = "Logging level for Chatbot notifications"
  type        = string
  default     = "ERROR"
  validation {
    condition     = contains(["NONE", "ERROR", "INFO"], var.logging_level)
    error_message = "logging_level must be one of NONE, ERROR, INFO"
  }
}

resource "aws_chatbot_slack_channel_configuration" "this" {
  configuration_name = "${var.env}-chatops"
  slack_channel_id   = var.slack_channel_id
  slack_team_id      = var.slack_team_id
  iam_role_arn       = var.iam_role_arn
  sns_topic_arns     = var.sns_topic_arns
  logging_level      = var.logging_level
}

output "chatops_configuration_name" {
  value = aws_chatbot_slack_channel_configuration.this.configuration_name
}
