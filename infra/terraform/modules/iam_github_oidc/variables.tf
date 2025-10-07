variable "env" { type = string }
variable "github_org" { type = string }
variable "github_repo" { type = string }
variable "allowed_passrole_arns" { type = list(string) default = [] }
variable "allowed_secrets_arns" { type = list(string) default = [] }
