output "db_endpoint" { value = aws_db_instance.this.endpoint }
output "db_secret_arn" { value = aws_secretsmanager_secret.db.arn }
output "db_instance_id" { value = aws_db_instance.this.id }
output "secret_rotation_lambda_arn" {
  value = try(aws_serverlessapplicationrepository_cloudformation_stack.rotation[0].outputs["RotationLambdaARN"], null)
}
output "secret_rotation_enabled" {
  value = var.enable_secret_rotation
}
