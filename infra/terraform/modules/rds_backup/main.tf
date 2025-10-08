locals { final_vault_name = coalesce(var.vault_name, "rds-backup-${var.env}") }

resource "aws_backup_vault" "this" {
  name = local.final_vault_name
}

resource "aws_backup_plan" "this" {
  name = "rds-backup-plan-${var.env}"
  rule {
    rule_name         = "daily"
    target_vault_name = aws_backup_vault.this.name
    schedule          = "cron(0 1 * * ? *)"
    lifecycle {
      cold_storage_after = var.cold_storage_after
      delete_after       = var.delete_after
    }
  }
}

resource "aws_backup_selection" "this" {
  name         = "rds-selection-${var.env}"
  iam_role_arn = aws_iam_role.backup.arn
  plan_id      = aws_backup_plan.this.id
  selection_tag {
    type  = "STRINGEQUALS"
    key   = var.selection_tag_key
    value = var.selection_tag_value
  }
}

resource "aws_iam_role" "backup" {
  name = "aws-backup-${var.env}-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "backup.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

output "backup_vault_name" { value = aws_backup_vault.this.name }
output "backup_plan_id" { value = aws_backup_plan.this.id }