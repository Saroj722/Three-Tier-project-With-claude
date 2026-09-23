# --- IAM Roles ---
#
# ECS Fargate needs two distinct roles, and mixing them up is a common
# beginner mistake worth understanding clearly:
#
#  - EXECUTION role: used by the ECS agent itself (not your app code) to
#    pull the container image from ECR and ship logs to CloudWatch,
#    before your application even starts running.
#  - TASK role: assumed by your application code at runtime, if it needs
#    to call other AWS services (e.g. S3, Secrets Manager, DynamoDB).
#    Our app doesn't call any AWS APIs directly, so this role currently
#    has no extra permissions - it exists so the pattern is in place if
#    you extend the app later (e.g. moving DB credentials into Secrets
#    Manager, which would need this role to have secretsmanager:GetSecretValue).

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_execution_role" {
  name               = "${var.project_name}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json

  tags = {
    Name = "${var.project_name}-ecs-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.project_name}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json

  tags = {
    Name = "${var.project_name}-ecs-task-role"
  }
}
