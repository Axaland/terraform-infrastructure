resource "aws_budgets_budget" "this" {
  name              = "monthly-${var.env}"
  budget_type       = "COST"
  limit_amount      = var.amount
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  cost_types { include_credit = true include_other_subscription = true include_upfront = true }
  cost_filter { name = "TagKeyValue" values = [for k,v in var.tags : "${k}$${v}"] }

  notification {
    comparison_operator = "GREATER_THAN"
    threshold           = 80
    threshold_type      = "PERCENTAGE"
    notification_type   = "ACTUAL"
    subscriber_email_addresses = var.emails
  }

  notification {
    comparison_operator = "GREATER_THAN"
    threshold           = 100
    threshold_type      = "PERCENTAGE"
    notification_type   = "FORECASTED"
    subscriber_email_addresses = var.emails
  }
}

output "budget_name" { value = aws_budgets_budget.this.name }
