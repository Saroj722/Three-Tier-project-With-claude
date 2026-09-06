terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # No remote backend configured yet - state is stored locally in
  # terraform.tfstate in this directory. Fine for a solo learning project,
  # but the very first thing a real team does is move this to an S3
  # backend with DynamoDB state locking so multiple engineers can safely
  # run terraform against the same infrastructure. Worth mentioning as a
  # known next step in interviews.
}

provider "aws" {
  region = var.aws_region
}
