variable "env" {
  type = string
}

variable "github_org" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "allowed_passrole_arns" {
  type    = list(string)
  default = []
}

variable "allowed_secrets_arns" {
  type    = list(string)
  default = []
}

variable "create_oidc_provider" {
  type    = bool
  default = true
}

variable "oidc_provider_arn" {
  type        = string
  default     = null
  description = "ARN di un provider OIDC GitHub già esistente (usato se create_oidc_provider=false)"

  validation {
    condition     = var.create_oidc_provider || var.oidc_provider_arn != null
    error_message = "Quando create_oidc_provider è false, devi fornire oidc_provider_arn."
  }
}
