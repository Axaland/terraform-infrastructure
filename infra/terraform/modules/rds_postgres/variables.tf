variable "env" { type = string }
variable "db_name" { type = string }
variable "username" { type = string }
variable "instance_class" { type = string default = "db.t4g.micro" }
variable "allocated_storage" { type = number default = 20 }
variable "max_allocated_storage" { type = number default = 100 }
variable "engine_version" { type = string default = "15.4" }
variable "subnet_ids" { type = list(string) }
variable "vpc_id" { type = string }
variable "backup_retention" { type = number default = 7 }
variable "allowed_cidr_blocks" { type = list(string) default = ["10.0.0.0/8"] }
