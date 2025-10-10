locals {
  lb_suffix_parts = split("loadbalancer/", var.load_balancer_arn)
  lb_suffix       = element(local.lb_suffix_parts, length(local.lb_suffix_parts) - 1)
  tg_suffix_parts = split("targetgroup/", var.target_group_arn)
  tg_suffix       = element(local.tg_suffix_parts, length(local.tg_suffix_parts) - 1)
  sns_topic_name  = "${var.env}-ops-alerts"
  alert_actions   = [aws_sns_topic.alerts.arn]
}

resource "aws_sns_topic" "alerts" {
  name         = local.sns_topic_name
  display_name = "${upper(var.env)} Ops Alerts"

  tags = {
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

resource "aws_sns_topic_subscription" "emails" {
  for_each = { for email in var.alert_emails : email => email }

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.env}-alb-target-5xx"
  alarm_description   = "${upper(var.env)} ALB target 5XX errors exceeded ${var.alb_5xx_threshold} in a 5-minute window."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = var.alb_5xx_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alert_actions
  ok_actions          = local.alert_actions

  dimensions = {
    LoadBalancer = local.lb_suffix
    TargetGroup  = local.tg_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "${var.env}-alb-unhealthy-hosts"
  alarm_description   = "${upper(var.env)} ALB detected unhealthy targets."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = var.unhealthy_host_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alert_actions
  ok_actions          = local.alert_actions

  dimensions = {
    LoadBalancer = local.lb_suffix
    TargetGroup  = local.tg_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  alarm_name          = "${var.env}-ecs-cpu-high"
  alarm_description   = "${upper(var.env)} ECS service CPU utilization over ${var.cpu_threshold}%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.cpu_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alert_actions
  ok_actions          = local.alert_actions

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory" {
  alarm_name          = "${var.env}-ecs-memory-high"
  alarm_description   = "${upper(var.env)} ECS service memory utilization over ${var.memory_threshold}%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.memory_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alert_actions
  ok_actions          = local.alert_actions

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}
