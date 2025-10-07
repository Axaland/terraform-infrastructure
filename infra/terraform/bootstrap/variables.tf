variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "project" {
  type    = string
  default = "terraform-infrastructure"
}

variable "state_bucket_force_destroy" {
  type    = bool
  default = true
}
