output "db_endpoint" { value = aws_db_instance.this.endpoint }
output "db_secret_arn" { value = aws_secretsmanager_secret.db.arn }
output "db_instance_id" { value = aws_db_instance.this.id }
