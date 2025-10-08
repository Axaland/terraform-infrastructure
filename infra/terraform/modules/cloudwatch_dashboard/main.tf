locals {
  lb_suffix_parts = split("loadbalancer/", var.load_balancer_arn)
  lb_suffix       = element(local.lb_suffix_parts, length(local.lb_suffix_parts) - 1)
  tg_suffix_parts = split("targetgroup/", var.target_group_arn)
  tg_suffix       = element(local.tg_suffix_parts, length(local.tg_suffix_parts) - 1)

  dashboard_body = jsonencode({
    widgets = [
      {
        type       = "text"
        x          = 0
        y          = 0
        width      = 24
        height     = 2
        properties = { markdown = "# Observability ${var.env}\nECS, RDS, ALB metrics" }
      },
      {
        type   = "metric"
        x      = 0
        y      = 2
        width  = 8
        height = 6
        properties = {
          title   = "ECS CPU %"
          metrics = [["AWS/ECS", "CPUUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name, { "stat" : "Average" }]]
          period  = 300
          region  = "eu-west-1"
          stat    = "Average"
          view    = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 2
        width  = 8
        height = 6
        properties = {
          title   = "RDS Conn"
          metrics = [["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.db_instance_id, { "stat" : "Average" }]]
          period  = 300
          region  = "eu-west-1"
          stat    = "Average"
          view    = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 2
        width  = 8
        height = 6
        properties = {
          title = "ALB 4xx/5xx"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_ELB_4XX_Count", "LoadBalancer", local.lb_suffix, { "stat" : "Sum" }],
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", local.lb_suffix, { "stat" : "Sum" }]
          ]
          period = 300
          region = "eu-west-1"
          stat   = "Sum"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 8
        width  = 12
        height = 6
        properties = {
          title   = "ALB Target Latency"
          metrics = [["AWS/ApplicationELB", "TargetResponseTime", "TargetGroup", local.tg_suffix, "LoadBalancer", local.lb_suffix, { "stat" : "Average" }]]
          period  = 300
          region  = "eu-west-1"
          stat    = "Average"
          view    = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 8
        width  = 12
        height = 6
        properties = {
          title = "RDS Storage & IOPS"
          metrics = [
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", var.db_instance_id, { "stat" : "Minimum" }],
            ["AWS/RDS", "WriteIOPS", "DBInstanceIdentifier", var.db_instance_id, { "stat" : "Average" }],
            ["AWS/RDS", "ReadIOPS", "DBInstanceIdentifier", var.db_instance_id, { "stat" : "Average" }]
          ]
          period = 300
          region = "eu-west-1"
          stat   = "Average"
          view   = "timeSeries"
        }
      }
    ]
  })
}

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "${var.env}-${var.dashboard_name}"
  dashboard_body = local.dashboard_body
}

output "dashboard_name" { value = aws_cloudwatch_dashboard.this.dashboard_name }
