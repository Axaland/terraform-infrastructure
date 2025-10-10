output "canary_name" {
  value = aws_synthetics_canary.this.name
}

output "artifact_bucket" {
  value = aws_s3_bucket.artifacts.bucket
}
