variable "env" {
  type = string
}

variable "canary_name" {
  type = string
}

variable "url" {
  type = string
}

variable "schedule_expression" {
  type    = string
  default = "rate(5 minutes)"
}

variable "runtime_version" {
  type    = string
  default = "syn-nodejs-puppeteer-7.0"
}

variable "timeout_in_seconds" {
  type    = number
  default = 60
}

variable "alarm_topic_arns" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "artifact_force_destroy" {
  type    = bool
  default = true
}
