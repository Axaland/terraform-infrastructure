terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    archive = {
      source = "hashicorp/archive"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

locals {
  base_name   = replace("${var.env}-${var.canary_name}", " ", "-")
  bucket_name = lower("synthetics-${local.base_name}-${random_id.bucket_suffix.hex}")
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "artifacts" {
  bucket        = local.bucket_name
  force_destroy = var.artifact_force_destroy
  tags          = merge(var.tags, { Environment = var.env, ManagedBy = "terraform" })
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "canary" {
  name = "${local.base_name}-synthetics-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      },
      {
        Effect    = "Allow"
        Principal = { Service = "synthetics.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
  tags = merge(var.tags, { Environment = var.env, ManagedBy = "terraform" })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.canary.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "synthetics_full_access" {
  role       = aws_iam_role.canary.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchSyntheticsFullAccess"
}

resource "aws_iam_role_policy" "bucket_write" {
  name = "${local.base_name}-synthetics-artifacts"
  role = aws_iam_role.canary.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"],
        Resource = [
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*"
        ]
      }
    ]
  })
}

data "archive_file" "canary_zip" {
  type        = "zip"
  output_path = "${path.module}/canary-${local.base_name}.zip"

  source {
    content  = templatefile("${path.module}/templates/canary.js.tpl", { url = var.url })
    filename = "index.js"
  }
}

resource "aws_synthetics_canary" "this" {
  name                 = local.base_name
  artifact_s3_location = "s3://${aws_s3_bucket.artifacts.bucket}"
  execution_role_arn   = aws_iam_role.canary.arn
  runtime_version      = var.runtime_version
  handler              = "index.handler"
  schedule {
    expression = var.schedule_expression
  }
  run_config {
    timeout_in_seconds = var.timeout_in_seconds
  }
  zip_file                 = data.archive_file.canary_zip.output_path
  start_canary             = true
  failure_retention_period = 31
  success_retention_period = 31
  tags                     = merge(var.tags, { Environment = var.env, ManagedBy = "terraform" })
  depends_on               = [aws_iam_role_policy.bucket_write, aws_s3_bucket_public_access_block.artifacts]
}

resource "aws_cloudwatch_metric_alarm" "canary_failed" {
  count               = length(var.alarm_topic_arns) > 0 ? 1 : 0
  alarm_name          = "${local.base_name}-failed"
  alarm_description   = "Canary ${local.base_name} ha rilevato un fallimento di availability."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Failed"
  namespace           = "CloudWatchSynthetics"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_topic_arns
  ok_actions          = var.alarm_topic_arns
  dimensions = {
    CanaryName = aws_synthetics_canary.this.name
  }
}