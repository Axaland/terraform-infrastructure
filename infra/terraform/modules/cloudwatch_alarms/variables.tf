variable "env" {
  type = string
}

variable "alert_emails" {
  type    = list(string)
  default = []
}

variable "load_balancer_arn" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "cpu_threshold" {
  type    = number
  default = 85
}

variable "memory_threshold" {
  type    = number
  default = 85
}

variable "alb_5xx_threshold" {
  type    = number
  default = 5
}

variable "unhealthy_host_threshold" {
  type    = number
  default = 0
}
