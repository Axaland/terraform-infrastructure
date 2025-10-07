variable "name" { type = string }
variable "cidr_block" { type = string }
variable "enable_nat" { type = bool default = true }
variable "public_subnet_cidrs" { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }
