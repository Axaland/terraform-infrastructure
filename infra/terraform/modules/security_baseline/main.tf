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
variable "required_tags" {
  type        = list(string)
  default     = ["Environment", "Owner"]
  description = "Lista dei tag richiesti per la regola AWS Config required-tags"
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
  depends_on     = [aws_config_configuration_recorder.this]
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

output "required_tags_rule_name" { value = try(aws_config_config_rule.required_tags[0].name, null) }

output "guardduty_detector_id" { value = try(aws_guardduty_detector.this[0].id, null) }
output "config_bucket_name" { value = try(aws_s3_bucket.config_snapshots[0].bucket, null) }
