variable "env" {
  type = string
}

variable "service_name" {
  type = string
}

variable "image" {
  type = string
}

variable "cpu" {
  type    = number
  default = 256
}

variable "memory" {
  type    = number
  default = 512
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "min_capacity" {
  type    = number
  default = 1
}

variable "max_capacity" {
  type    = number
  default = 4
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "container_port" {
  type    = number
  default = 3000
}

variable "vpc_id" {
  type = string
}

variable "load_balancer_arn" {
  type = string
}

variable "listener_port" {
  type    = number
  default = 80
}

variable "listener_protocol" {
  type    = string
  default = "HTTP"
}

variable "secrets" {
  type        = map(string)
  default     = {}
  description = "Mappa ENV_VAR => ARN secret"
}

variable "environment" {
  type        = map(string)
  default     = {}
  description = "Mappa ENV_VAR => valore in chiaro"
}

variable "alb_security_group_id" {
  type        = string
  description = "Security group dell'ALB autorizzato verso il servizio"
}

variable "health_check_path" {
  type        = string
  default     = "/"
  description = "Percorso HTTP da utilizzare per l'health check del target group"
}
