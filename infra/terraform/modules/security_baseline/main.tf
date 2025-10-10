variable "env" {
  type = string
}

variable "config_snapshot_retention_days" {
  type    = number
  default = 90
}

variable "enable_guardduty" {
  type    = bool
  default = true
}

variable "enable_config" {
  type    = bool
  default = true
}

variable "config_notification_emails" {
  type        = list(string)
  default     = []
  description = "Lista di indirizzi email da iscrivere agli alert di compliance AWS Config"
}

variable "managed_rules" {
  description = "Configurazione delle regole AWS Config gestite da distribuire"
  type = list(object({
    name              = string
    source_identifier = string
    input_parameters  = optional(map(string))
  }))
  default = [
    {
      name              = "s3-bucket-public-read-prohibited"
      source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
    },
    {
      name              = "s3-bucket-public-write-prohibited"
      source_identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
    },
    {
      name              = "rds-storage-encrypted"
      source_identifier = "RDS_STORAGE_ENCRYPTED"
    },
    {
      name              = "ebs-encryption-by-default"
      source_identifier = "EBS_ENCRYPTION_BY_DEFAULT"
    },
    {
      name              = "incoming-ssh-disabled"
      source_identifier = "INCOMING_SSH_DISABLED"
      input_parameters  = { sshFromPort = 22, sshToPort = 22 }
    }
  ]
}
variable "required_tags" {
  type        = list(string)
  default     = ["Environment", "Owner"]
  description = "Lista dei tag richiesti per la regola AWS Config required-tags"
}

variable "enable_conformance_pack" {
  type        = bool
  default     = false
  description = "Se true, distribuisce un AWS Config Conformance Pack alignato al CIS"
}

variable "conformance_pack_name" {
  type        = string
  default     = null
  description = "Nome custom per il conformance pack (default: <env>-cis-ops)"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  bucket_name           = "config-snapshots-${var.env}-${data.aws_caller_identity.current.account_id}"
  required_tags_limited = slice(var.required_tags, 0, min(length(var.required_tags), 5))
  required_tags_map = {
    for idx, tag in local.required_tags_limited :
    "tag${idx + 1}Key" => tag
  }
  managed_rules_map = {
    for rule in var.managed_rules :
    rule.name => rule
  }
}

resource "aws_s3_bucket" "config_snapshots" {
  count  = var.enable_config ? 1 : 0
  bucket = local.bucket_name
}

resource "aws_s3_bucket_versioning" "config_snapshots" {
  count  = var.enable_config ? 1 : 0
  bucket = aws_s3_bucket.config_snapshots[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config_snapshots" {
  count  = var.enable_config ? 1 : 0
  bucket = aws_s3_bucket.config_snapshots[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "config_snapshots" {
  count  = var.enable_config ? 1 : 0
  bucket = aws_s3_bucket.config_snapshots[0].id

  rule {
    id     = "expire"
    status = "Enabled"

    expiration {
      days = var.config_snapshot_retention_days
    }
  }
}

resource "aws_guardduty_detector" "this" {
  count  = var.enable_guardduty ? 1 : 0
  enable = true
}

resource "aws_guardduty_detector_feature" "s3_logs" {
  count       = var.enable_guardduty ? 1 : 0
  detector_id = aws_guardduty_detector.this[0].id
  name        = "S3_DATA_EVENTS"
  status      = "ENABLED"
}

resource "aws_iam_role" "config_role" {
  count = var.enable_config ? 1 : 0
  name  = "${var.env}-config-recorder-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "config.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy" "config_inline" {
  count = var.enable_config ? 1 : 0
  name  = "${var.env}-config-inline"
  role  = aws_iam_role.config_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "config:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation",
          "sns:Publish"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = aws_iam_role.config_role[0].arn
      }
    ]
  })
}

resource "aws_config_configuration_recorder" "this" {
  count    = var.enable_config ? 1 : 0
  name     = "${var.env}-recorder"
  role_arn = aws_iam_role.config_role[0].arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "this" {
  count          = var.enable_config ? 1 : 0
  name           = "${var.env}-delivery"
  s3_bucket_name = aws_s3_bucket.config_snapshots[0].bucket
  sns_topic_arn  = aws_sns_topic.config_notifications[0].arn
  depends_on     = [aws_config_configuration_recorder.this]
}

resource "aws_sns_topic" "config_notifications" {
  count        = var.enable_config ? 1 : 0
  name         = "config-compliance-${var.env}"
  display_name = "${var.env} AWS Config compliance"
}

resource "aws_sns_topic_subscription" "config_notifications_email" {
  for_each  = var.enable_config ? toset(var.config_notification_emails) : []
  topic_arn = aws_sns_topic.config_notifications[0].arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_s3_bucket_policy" "config_snapshots" {
  count  = var.enable_config ? 1 : 0
  bucket = aws_s3_bucket.config_snapshots[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSConfigBucketPermissionsCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = [
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ]
        Resource = aws_s3_bucket.config_snapshots[0].arn
      },
      {
        Sid    = "AWSConfigBucketDelivery"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.config_snapshots[0].arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
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
  input_parameters = jsonencode(local.required_tags_map)
  depends_on       = [aws_config_configuration_recorder_status.this]
}

resource "aws_config_config_rule" "managed" {
  for_each = var.enable_config ? local.managed_rules_map : {}
  name     = "${each.key}-${var.env}"
  source {
    owner             = "AWS"
    source_identifier = each.value.source_identifier
  }
  input_parameters = lookup(each.value, "input_parameters", null) == null ? null : jsonencode(each.value.input_parameters)
  depends_on       = [aws_config_configuration_recorder_status.this]
}

resource "aws_config_conformance_pack" "cis" {
  count         = var.enable_config && var.enable_conformance_pack ? 1 : 0
  name          = coalesce(var.conformance_pack_name, "${var.env}-cis-ops")
  template_body = file("${path.module}/templates/cis_operational_best_practices.yaml")
  depends_on    = [aws_config_configuration_recorder_status.this]
}

output "required_tags_rule_name" { value = try(aws_config_config_rule.required_tags[0].name, null) }

output "guardduty_detector_id" { value = try(aws_guardduty_detector.this[0].id, null) }
output "config_bucket_name" { value = try(aws_s3_bucket.config_snapshots[0].bucket, null) }
output "config_sns_topic_arn" { value = try(aws_sns_topic.config_notifications[0].arn, null) }
output "config_rule_names" {
  value = var.enable_config ? [for rule in aws_config_config_rule.managed : rule.name] : []
}

output "conformance_pack_name" {
  value = try(aws_config_conformance_pack.cis[0].name, null)
}
