# --- Pipeline artifact storage + GitHub connection ---

# CodePipeline needs somewhere to hand off files between stages (source
# code zip from GitHub -> CodeBuild, then imagedefinitions.json from
# CodeBuild -> the ECS deploy actions). S3 is that hand-off point.
resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket = "${var.project_name}-pipeline-artifacts-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.project_name}-pipeline-artifacts"
  }
}

resource "aws_s3_bucket_public_access_block" "pipeline_artifacts" {
  bucket = aws_s3_bucket.pipeline_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "pipeline_artifacts" {
  bucket = aws_s3_bucket.pipeline_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_caller_identity" "current" {}

# CodeStar Connections is how CodePipeline authenticates to GitHub without
# you ever handing it a personal access token. Terraform can CREATE this
# connection, but cannot complete the OAuth handshake for you - that one
# step has to happen manually in the AWS Console after `apply` (see the
# instructions that follow). The connection sits in PENDING status until
# you do that; the pipeline simply won't pull source until it's ACTIVE.
resource "aws_codestarconnections_connection" "github" {
  name          = "${var.project_name}-github"
  provider_type = "GitHub"
}
