# --- ECS Cluster, Task Definitions, Services ---

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled" # extra CloudWatch metrics per service/task - small cost, worth it for a resume project's monitoring story
  }

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.project_name}/frontend"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.project_name}/backend"
  retention_in_days = var.log_retention_days
}

# --- Frontend task + service ---

resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.project_name}-frontend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc" # required for Fargate - each task gets its own ENI
  cpu                      = var.frontend_cpu
  memory                   = var.frontend_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn             = aws_iam_role.ecs_task_role.arn

  # NOTE: ":latest" is a placeholder so `terraform apply` succeeds even
  # before any image has been pushed. The task will fail to reach a
  # steady state until you push a real image (see the manual push steps
  # after this applies). Phase 4's CI/CD pipeline replaces this tag with
  # a specific commit SHA on every deploy - "latest" is fine to bootstrap
  # with but is not what you want driving deployments long-term, since
  # you can't tell which code is actually running from the tag alone.
  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "${aws_ecr_repository.frontend.repository_url}:latest"
      essential = true
      portMappings = [{
        containerPort = var.frontend_container_port
        protocol      = "tcp"
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.frontend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "frontend"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-frontend-task"
  }
}

resource "aws_ecs_service" "frontend" {
  name            = "${var.project_name}-frontend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = var.frontend_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.frontend.id]
    assign_public_ip = false # egress via NAT gateway instead
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name    = "frontend"
    container_port    = var.frontend_container_port
  }

  health_check_grace_period_seconds = 60

  depends_on = [aws_lb_listener.http]

  tags = {
    Name = "${var.project_name}-frontend-service"
  }
}

# --- Backend task + service ---

resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project_name}-backend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.backend_cpu
  memory                   = var.backend_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn             = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "${aws_ecr_repository.backend.repository_url}:latest"
      essential = true
      portMappings = [{
        containerPort = var.backend_container_port
        protocol      = "tcp"
      }]
      environment = [
        { name = "PORT", value = tostring(var.backend_container_port) },
        { name = "DB_HOST", value = aws_db_instance.main.address },
        { name = "DB_PORT", value = "3306" },
        { name = "DB_USER", value = var.db_username },
        { name = "DB_NAME", value = var.db_name },
      ]
      # DB_PASSWORD deliberately NOT here as plain text - see secrets below.
      secrets = [
        { name = "DB_PASSWORD", valueFrom = aws_ssm_parameter.db_password.arn }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "backend"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-backend-task"
  }
}

# The DB password needs to reach the container without ever appearing in
# plain text in the task definition (which is visible to anyone with
# ECS read access) or in Terraform's plan output as a literal. SSM
# Parameter Store (SecureString) plus the "secrets" block above is the
# standard lightweight way to do this - Secrets Manager is the
# heavier/more expensive alternative with built-in rotation.
resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.project_name}/db_password"
  type  = "SecureString"
  value = var.db_password

  tags = {
    Name = "${var.project_name}-db-password"
  }
}

resource "aws_iam_role_policy" "ecs_execution_ssm_read" {
  name = "${var.project_name}-ssm-read"
  role = aws_iam_role.ecs_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameters"]
      Resource = [aws_ssm_parameter.db_password.arn]
    }]
  })
}

resource "aws_ecs_service" "backend" {
  name            = "${var.project_name}-backend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = var.backend_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.backend.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name    = "backend"
    container_port    = var.backend_container_port
  }

  health_check_grace_period_seconds = 60

  depends_on = [aws_lb_listener.http, aws_db_instance.main]

  tags = {
    Name = "${var.project_name}-backend-service"
  }
}
