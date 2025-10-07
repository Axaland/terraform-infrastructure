resource "aws_ecs_cluster" "this" {
  name = "${var.env}-${var.service_name}-cluster"
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.env}/${var.service_name}"
  retention_in_days = 30
}

resource "aws_iam_role" "task_exec" {
  name = "${var.env}-${var.service_name}-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "task_exec" {
  role       = aws_iam_role.task_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

locals {
  container_secrets = [ for k, v in var.secrets : { name = k, valueFrom = v } ]
  container_def = {
    name      = var.service_name
    image     = var.image
    essential = true
    portMappings = [{ containerPort = var.container_port, hostPort = var.container_port, protocol = "tcp" }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.this.name
        awslogs-region        = data.aws_region.current.name
        awslogs-stream-prefix = "ecs"
      }
    }
    secrets = local.container_secrets
  }
}

data "aws_region" "current" {}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.env}-${var.service_name}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.task_exec.arn
  container_definitions    = jsonencode([local.container_def])
}

resource "aws_security_group" "service" {
  name        = "${var.env}-${var.service_name}-sg"
  description = "Service ingress"
  vpc_id      = var.vpc_id
  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_lb_target_group" "this" {
  name        = "tg-${var.env}-${var.service_name}"
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check { path = "/" matcher = "200-399" }
}

resource "aws_ecs_service" "this" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.service.id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.service_name
    container_port   = var.container_port
  }
  lifecycle { ignore_changes = [desired_count] }
}

resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace
  target_tracking_scaling_policy_configuration {
    target_value       = 50
    predefined_metric_specification { predefined_metric_type = "ECSServiceAverageCPUUtilization" }
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

output "service_name" { value = aws_ecs_service.this.name }
output "cluster_arn" { value = aws_ecs_cluster.this.arn }
output "cluster_name" { value = aws_ecs_cluster.this.name }
output "target_group_arn" { value = aws_lb_target_group.this.arn }
