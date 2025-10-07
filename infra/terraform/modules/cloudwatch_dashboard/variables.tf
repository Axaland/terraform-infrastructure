variable "env" { type = string }
variable "dashboard_name" { type = string default = "platform-observability" }
variable "ecs_cluster_name" { type = string }
variable "ecs_service_name" { type = string }
variable "target_group_arn" { type = string }
variable "load_balancer_arn" { type = string }
variable "db_instance_id" { type = string }
