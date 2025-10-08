variable "env" {
  type = string
}

variable "alb_arn" {
  type = string
}

variable "rate_limit" {
  type    = number
  default = 2000
}
