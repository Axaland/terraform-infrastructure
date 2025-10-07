variable "env" { type = string }
variable "config_snapshot_retention_days" { type = number default = 90 }
variable "enable_guardduty" { type = bool default = true }
variable "enable_config" { type = bool default = true }
variable "required_tags" {
  type        = list(string)
  default     = ["Environment", "Owner"]
  description = "Lista dei tag richiesti per la regola AWS Config required-tags"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals { bucket_name = "config-snapshots-${var.env}-${data.aws_caller_identity.current.account_id}" }

resource "aws_s3_bucket" "config_snapshots" {
  count = var.enable_config ? 1 : 0
  bucket = local.bucket_name
  versioning { enabled = true }
  server_side_encryption_configuration { rule { apply_server_side_encryption_by_default { sse_algorithm = "AES256" } } }
  lifecycle_rule {
    id      = "expire"
    enabled = true
    expiration { days = var.config_snapshot_retention_days }
  }
}

resource "aws_guardduty_detector" "this" {
  count  = var.enable_guardduty ? 1 : 0
  enable = true
  datasources { s3_logs { enable = true } }
}

resource "aws_iam_role" "config_role" {
  count = var.enable_config ? 1 : 0
  name  = "${var.env}-config-recorder-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "config.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy_attachment" "config_managed" {
  count      = var.enable_config ? 1 : 0
  role       = aws_iam_role.config_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

resource "aws_config_configuration_recorder" "this" {
  count    = var.enable_config ? 1 : 0
  name     = "${var.env}-recorder"
  role_arn = aws_iam_role.config_role[0].arn
  recording_group { all_supported = true include_global_resource_types = true }
}

resource "aws_config_delivery_channel" "this" {
  count          = var.enable_config ? 1 : 0
  name           = "${var.env}-delivery"
  s3_bucket_name = aws_s3_bucket.config_snapshots[0].bucket
  depends_on     = [aws_config_configuration_recorder.this]
}

resource "aws_config_configuration_recorder_status" "this" {
  count      = var.enable_config ? 1 : 0
  is_enabled = true
  name       = aws_config_configuration_recorder.this[0].name
  depends_on = [aws_config_delivery_channel.this]
}

# Regola required-tags (solo se Config abilitato)
resource "aws_config_config_rule" "required_tags" {
  count = var.enable_config ? 1 : 0
  name  = "required-tags-${var.env}"
  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }
  input_parameters = jsonencode({
    tag1Key = try(var.required_tags[0], null)
    tag2Key = try(var.required_tags[1], null)
    tag3Key = try(var.required_tags[2], null)
    tag4Key = try(var.required_tags[3], null)
    tag5Key = try(var.required_tags[4], null)
  })
  depends_on = [aws_config_configuration_recorder_status.this]
}

output "required_tags_rule_name" { value = try(aws_config_config_rule.required_tags[0].name, null) }

output "guardduty_detector_id" { value = try(aws_guardduty_detector.this[0].id, null) }
output "config_bucket_name" { value = try(aws_s3_bucket.config_snapshots[0].bucket, null) }
