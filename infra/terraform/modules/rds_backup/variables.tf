variable "env" {
  type = string
}

variable "selection_tag_key" {
  type    = string
  default = "Backup"
}

variable "selection_tag_value" {
  type    = string
  default = "true"
}

variable "cold_storage_after" {
  type    = number
  default = 30
}

variable "delete_after" {
  type    = number
  default = 120
}

variable "vault_name" {
  type    = string
  default = null
}

variable "enable_cross_region_copy" {
  type    = bool
  default = false
}

variable "copy_destination_vault_name" {
  type    = string
  default = null
}
