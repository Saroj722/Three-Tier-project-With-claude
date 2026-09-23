# --- CodeBuild ---
# Runs buildspec.yml (at the repo root) - builds both images, pushes to
# ECR, and emits the two imagedefinitions*.json files the ECS deploy
# actions need. See buildspec.yml for the actual build steps.

resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/codebuild/${var.project_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_codebuild_project" "app" {
  name         = "${var.project_name}-build"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true # required - CodeBuild needs to run its own Docker daemon to build images

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }
    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
    }
    environment_variable {
      name  = "FRONTEND_REPO_URL"
      value = aws_ecr_repository.frontend.repository_url
    }
    environment_variable {
      name  = "BACKEND_REPO_URL"
      value = aws_ecr_repository.backend.repository_url
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml" # lives at the repo root
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild.name
    }
  }

  tags = {
    Name = "${var.project_name}-build"
  }
}
