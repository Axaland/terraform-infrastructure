variable "env" {
  type = string
}

variable "alert_threshold" {
  description = "Soglia in USD che scatena una notifica di anomalia"
  type        = number
  default     = 50
}

variable "frequency" {
  description = "Frequenza con cui vengono inviate le notifiche (DAILY, IMMEDIATE)"
  type        = string
  default     = "DAILY"
}

variable "emails" {
  description = "Lista di indirizzi email da iscrivere alle notifiche di anomalia costi"
  type        = list(string)
  default     = []
}

variable "monitor_tags" {
  description = "Mappa di tag cost allocation (chiave -> valore) per filtrare il monitor"
  type        = map(string)
  default     = {}
}

variable "enable_forecast_subscription" {
  description = "Crea un secondo abbonamento per le anomalie forecasted"
  type        = bool
  default     = true
}

variable "forecast_threshold" {
  description = "Soglia in USD per le notifiche forecasted"
  type        = number
  default     = 100
}

resource "aws_sns_topic" "anomaly_alerts" {
  name         = "cost-anomaly-${var.env}"
  display_name = "${var.env} Cost Anomaly Alerts"
}

resource "aws_sns_topic_subscription" "emails" {
  for_each  = toset(var.emails)
  topic_arn = aws_sns_topic.anomaly_alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_ce_anomaly_monitor" "service" {
  name              = "${var.env}-service-anomaly-monitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

locals {
  tag_monitor_spec = jsonencode({
    Tags = [
      for key, value in var.monitor_tags : {
        Key    = key
        Values = [value]
      }
    ]
  })
}

resource "aws_ce_anomaly_monitor" "tag" {
  count                 = length(var.monitor_tags) > 0 ? 1 : 0
  name                  = "${var.env}-tag-anomaly-monitor"
  monitor_type          = "CUSTOM"
  monitor_specification = local.tag_monitor_spec
}

locals {
  monitor_arns = compact(concat(
    [aws_ce_anomaly_monitor.service.arn],
    [for m in aws_ce_anomaly_monitor.tag : m.arn]
  ))
}

resource "aws_ce_anomaly_subscription" "service" {
  name             = "${var.env}-service-anomaly-subscription"
  frequency        = var.frequency
  monitor_arn_list = local.monitor_arns

  subscriber {
    type    = "SNS"
    address = aws_sns_topic.anomaly_alerts.arn
  }

  threshold_expression {
    dimension {
      key    = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      values = [tostring(var.alert_threshold)]
    }
  }
}

resource "aws_ce_anomaly_subscription" "forecast" {
  count            = var.enable_forecast_subscription ? 1 : 0
  name             = "${var.env}-forecast-anomaly-subscription"
  frequency        = var.frequency
  monitor_arn_list = local.monitor_arns

  subscriber {
    type    = "SNS"
    address = aws_sns_topic.anomaly_alerts.arn
  }

  threshold_expression {
    dimension {
      key    = "ANOMALY_TOTAL_IMPACT_FORECAST"
      values = [tostring(var.forecast_threshold)]
    }
  }
}

output "sns_topic_arn" {
  value = aws_sns_topic.anomaly_alerts.arn
}

output "monitor_arn" {
  value = aws_ce_anomaly_monitor.service.arn
}

output "forecast_subscription_arn" {
  value = try(aws_ce_anomaly_subscription.forecast[0].arn, null)
}
