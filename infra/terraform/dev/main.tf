module "vpc" {
  source               = "../modules/vpc"
  name                 = "${var.env_name}-vpc"
  cidr_block           = var.vpc_cidr
  enable_nat           = var.enable_nat
  public_subnet_cidrs  = var.public_subnets
  private_subnet_cidrs = var.private_subnets
}

module "rds" {
  source                 = "../modules/rds_postgres"
  env                    = var.env_name
  db_name                = var.db_name
  username               = var.db_user
  subnet_ids             = module.vpc.private_subnet_ids
  vpc_id                 = module.vpc.vpc_id
  allowed_cidr_blocks    = var.rds_allowed_cidrs
  multi_az               = false
  enable_secret_rotation = true
  rotation_interval_days = var.rds_rotation_interval_days
}

module "ecr" {
  source       = "../modules/ecr"
  repositories = ["app"]
}

locals {
  service_image = length(trimspace(var.service_image)) > 0 ? var.service_image : "${module.ecr.repository_urls["app"]}:${var.service_image_tag}"
}

module "service" {
  source                = "../modules/ecs_fargate_service"
  env                   = var.env_name
  service_name          = "app"
  image                 = local.service_image
  private_subnet_ids    = module.vpc.private_subnet_ids
  vpc_id                = module.vpc.vpc_id
  load_balancer_arn     = aws_lb.app.arn
  alb_security_group_id = aws_security_group.alb.id
  health_check_path     = "/health"
  desired_count         = 2
  min_capacity          = 2
  secrets = {
    DB_PASSWORD = module.rds.db_secret_arn
  }
}

resource "aws_security_group" "alb" {
  name        = "${var.env_name}-alb-sg"
  description = "Ingress HTTP per ALB ${var.env_name}"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ALB pubblico per il servizio
resource "aws_lb" "app" {
  name               = "${var.env_name}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnet_ids
  security_groups    = [aws_security_group.alb.id]
}

module "waf" {
  source     = "../modules/waf_alb"
  env        = var.env_name
  alb_arn    = aws_lb.app.arn
  rate_limit = var.waf_rate_limit
}

module "budget" {
  source = "../modules/budgets"
  env    = var.env_name
  amount = var.monthly_budget_amount
  emails = var.budget_alert_emails
  tags   = { Environment = var.env_name }
}

module "cost_anomaly_detection" {
  source                       = "../modules/cost_anomaly_detection"
  env                          = var.env_name
  alert_threshold              = var.cost_anomaly_threshold
  emails                       = var.cost_anomaly_emails
  forecast_threshold           = var.cost_anomaly_forecast_threshold
  monitor_tags                 = var.cost_anomaly_monitor_tags
  enable_forecast_subscription = var.cost_anomaly_enable_forecast
}

module "security_baseline" {
  source                         = "../modules/security_baseline"
  env                            = var.env_name
  config_snapshot_retention_days = 120
  enable_guardduty               = var.enable_guardduty
  enable_config                  = true
  required_tags                  = ["Environment", "Owner", "CostCenter"]
  config_notification_emails     = var.config_notification_emails
  enable_conformance_pack        = var.enable_conformance_pack
}

output "config_conformance_pack" {
  value = module.security_baseline.conformance_pack_name
}

module "dashboard" {
  source            = "../modules/cloudwatch_dashboard"
  env               = var.env_name
  ecs_cluster_name  = module.service.cluster_name
  ecs_service_name  = module.service.service_name
  target_group_arn  = module.service.target_group_arn
  load_balancer_arn = aws_lb.app.arn
  db_instance_id    = module.rds.db_instance_id
}

module "alerts" {
  source            = "../modules/cloudwatch_alarms"
  env               = var.env_name
  alert_emails      = var.alert_emails
  load_balancer_arn = aws_lb.app.arn
  target_group_arn  = module.service.target_group_arn
  ecs_cluster_name  = module.service.cluster_name
  ecs_service_name  = module.service.service_name
}

module "rds_backup" {
  source = "../modules/rds_backup"
  providers = {
    aws         = aws
    aws.replica = aws.backup_replica
  }
  env                         = var.env_name
  selection_tag_key           = "Backup"
  selection_tag_value         = "true"
  enable_cross_region_copy    = true
  copy_destination_vault_name = var.backup_replica_vault_name
}

module "synthetic_health" {
  source              = "../modules/cloudwatch_synthetics_canary"
  env                 = var.env_name
  canary_name         = "app-health"
  url                 = "http://${aws_lb.app.dns_name}/health"
  schedule_expression = var.healthcheck_schedule_expression
  timeout_in_seconds  = var.synthetic_timeout_seconds
  alarm_topic_arns    = [module.alerts.sns_topic_arn]
  tags                = { Environment = var.env_name, ManagedBy = "terraform" }
}

module "ci_oidc" {
  source                = "../modules/iam_github_oidc"
  env                   = var.env_name
  github_org            = var.github_org
  github_repo           = var.github_repo
  allowed_passrole_arns = [module.service.task_execution_role_arn]
  allowed_secrets_arns  = [module.rds.db_secret_arn]
}
