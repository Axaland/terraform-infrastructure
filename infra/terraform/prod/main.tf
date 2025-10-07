module "vpc" { source = "../modules/vpc" name = "${var.env_name}-vpc" cidr_block = var.vpc_cidr enable_nat = true public_subnet_cidrs = var.public_subnets private_subnet_cidrs = var.private_subnets }

module "rds" { source = "../modules/rds_postgres" env = var.env_name db_name = var.db_name username = var.db_user subnet_ids = module.vpc.private_subnet_ids vpc_id = module.vpc.vpc_id backup_retention = 14 allowed_cidr_blocks = var.rds_allowed_cidrs }

module "ecr" { source = "../modules/ecr" repositories = ["app"] }

module "service" { source = "../modules/ecs_fargate_service" env = var.env_name service_name = "app" image = var.service_image private_subnet_ids = module.vpc.private_subnet_ids vpc_id = module.vpc.vpc_id secrets = { DB_PASSWORD = module.rds.db_secret_arn } desired_count = 3 min_capacity = 3 max_capacity = 10 }

resource "aws_lb" "app" { name = "${var.env_name}-alb" internal = false load_balancer_type = "application" subnets = module.vpc.public_subnet_ids security_groups = [] }

resource "aws_lb_listener" "http" { load_balancer_arn = aws_lb.app.arn port = 80 protocol = "HTTP" default_action { type = "forward" target_group_arn = module.service.target_group_arn } }

module "waf" { source = "../modules/waf_alb" env = var.env_name alb_arn = aws_lb.app.arn rate_limit = var.waf_rate_limit }

module "budget" { source = "../modules/budgets" env = var.env_name amount = var.monthly_budget_amount emails = var.budget_alert_emails tags = { Environment = var.env_name } }

module "security_baseline" { source = "../modules/security_baseline" env = var.env_name config_snapshot_retention_days = 180 enable_guardduty = true enable_config = true required_tags = ["Environment","Owner","CostCenter"] }
module "dashboard" { source = "../modules/cloudwatch_dashboard" env = var.env_name ecs_cluster_name = module.service.cluster_name ecs_service_name = module.service.service_name target_group_arn = module.service.target_group_arn load_balancer_arn = aws_lb.app.arn db_instance_id = module.rds.db_instance_id }
module "rds_backup" { source = "../modules/rds_backup" env = var.env_name selection_tag_key = "Backup" selection_tag_value = "true" }
