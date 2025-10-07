variable "env" { type = string }
variable "amount" { type = number }
variable "emails" { type = list(string) default = [] }
variable "tags" { type = map(string) default = {} }
