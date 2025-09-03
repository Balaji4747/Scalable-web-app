# Data source for AWS account ID
data "aws_caller_identity" "current" {}

# CodeBuild Project
resource "aws_codebuild_project" "app_build" {
  name         = "${var.project_name}-build"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                      = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                       = "LINUX_CONTAINER"
    privileged_mode            = true
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.app.name
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }
  }

  source {
    type = "NO_SOURCE"
    buildspec = "version: 0.2\nphases:\n  pre_build:\n    commands:\n      - echo Logging in to Amazon ECR...\n      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com\n  build:\n    commands:\n      - echo Build started on `date`\n      - echo Building the Docker image...\n      - docker build -t $IMAGE_REPO_NAME:$IMAGE_TAG ./app\n      - docker tag $IMAGE_REPO_NAME:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG\n  post_build:\n    commands:\n      - echo Build completed on `date`\n      - echo Pushing the Docker image...\n      - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG"
  }
}