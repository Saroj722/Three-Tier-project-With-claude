# --- CodePipeline ---
# Source (GitHub via CodeStar connection) -> Build (CodeBuild, both images)
# -> Deploy (two parallel native ECS deploy actions, one per service).
#
# The two Deploy actions run in the SAME stage with the SAME run_order,
# which means CodePipeline executes them in parallel - intentional, since
# frontend and backend are independent services with no deploy-ordering
# dependency between them.

resource "aws_codepipeline" "app" {
  name     = "${var.project_name}-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.pipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = "${var.github_repo_owner}/${var.github_repo_name}"
        BranchName       = var.github_branch
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.app.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "DeployBackend"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]
      run_order       = 1

      configuration = {
        ClusterName = aws_ecs_cluster.main.name
        ServiceName = aws_ecs_service.backend.name
        FileName    = "imagedefinitions-backend.json"
      }
    }

    action {
      name            = "DeployFrontend"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]
      run_order       = 1 # same run_order as DeployBackend -> executes in parallel

      configuration = {
        ClusterName = aws_ecs_cluster.main.name
        ServiceName = aws_ecs_service.frontend.name
        FileName    = "imagedefinitions-frontend.json"
      }
    }
  }

  tags = {
    Name = "${var.project_name}-pipeline"
  }
}
