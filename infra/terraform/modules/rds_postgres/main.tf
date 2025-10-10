resource "random_password" "password" {
  length           = 24
  special          = true
  override_special = "!#$%^&*()-_=+[]{}<>?"
}

resource "aws_secretsmanager_secret" "db" {
  name = "rds-${var.env}-credentials"
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({ username = var.username, password = random_password.password.result })
}

resource "aws_db_subnet_group" "this" {
  name       = "rds-${var.env}-subnets"
  subnet_ids = var.subnet_ids
}

resource "aws_security_group" "db" {
  name        = "rds-${var.env}-sg"
  description = "RDS access"
  vpc_id      = var.vpc_id
  dynamic "ingress" {
    for_each = var.allowed_cidr_blocks
    content {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }
  dynamic "ingress" {
    for_each = var.enable_secret_rotation ? { rotation = aws_security_group.rotation[0].id } : {}
    content {
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-${var.env}-sg"
  }
}

resource "aws_security_group" "rotation" {
  count       = var.enable_secret_rotation ? 1 : 0
  name        = "rds-${var.env}-rotation-sg"
  description = "Lambda secret rotation access to RDS"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-${var.env}-rotation-sg"
  }
}

resource "aws_db_instance" "this" {
  identifier              = "rds-${var.env}"
  engine                  = "postgres"
  engine_version          = var.engine_version
  instance_class          = var.instance_class
  db_name                 = var.db_name
  username                = var.username
  password                = random_password.password.result
  allocated_storage       = var.allocated_storage
  max_allocated_storage   = var.max_allocated_storage
  storage_encrypted       = true
  multi_az                = var.multi_az
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.db.id]
  backup_retention_period = var.backup_retention
  skip_final_snapshot     = true
  deletion_protection     = false
  publicly_accessible     = false
}

resource "aws_serverlessapplicationrepository_cloudformation_stack" "rotation" {
  count            = var.enable_secret_rotation ? 1 : 0
  name             = "rds-${var.env}-rotation"
  application_id   = "arn:aws:serverlessrepo:us-east-1:297356227824:applications/SecretsManagerRDSPostgreSQLRotationSingleUser"
  semantic_version = "1.1.0"

  parameters = {
    functionName        = "rds-${var.env}-rotation"
    masterSecretArn     = aws_secretsmanager_secret.db.arn
    secretArn           = aws_secretsmanager_secret.db.arn
    vpcSecurityGroupIds = join(",", [aws_security_group.rotation[0].id])
    vpcSubnetIds        = join(",", var.subnet_ids)
  }

  capabilities = ["CAPABILITY_IAM"]
}

resource "aws_secretsmanager_secret_rotation" "this" {
  count               = var.enable_secret_rotation ? 1 : 0
  secret_id           = aws_secretsmanager_secret.db.id
  rotation_lambda_arn = aws_serverlessapplicationrepository_cloudformation_stack.rotation[0].outputs["RotationLambdaARN"]

  rotation_rules {
    automatically_after_days = var.rotation_interval_days
  }
}
