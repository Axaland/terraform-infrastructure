variable "env" { type = string }
variable "service_name" { type = string }
variable "image" { type = string }
variable "cpu" { type = number default = 256 }
variable "memory" { type = number default = 512 }
variable "desired_count" { type = number default = 1 }
variable "min_capacity" { type = number default = 1 }
variable "max_capacity" { type = number default = 4 }
variable "private_subnet_ids" { type = list(string) }
variable "container_port" { type = number default = 3000 }
variable "vpc_id" { type = string }
variable "secrets" { type = map(string) default = {} description = "Mappa ENV_VAR => ARN secret" }
