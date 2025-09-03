#!/bin/bash

# Trigger CodeBuild project
PROJECT_NAME="scalable-web-app-build"
REGION="us-west-2"

echo "Starting CodeBuild project: $PROJECT_NAME"

BUILD_ID=$(aws codebuild start-build \
    --project-name $PROJECT_NAME \
    --region $REGION \
    --query 'build.id' \
    --output text)

echo "Build started with ID: $BUILD_ID"
echo "Monitor build at: https://$REGION.console.aws.amazon.com/codesuite/codebuild/projects/$PROJECT_NAME/build/$BUILD_ID"

# Wait for build to complete (optional)
echo "Waiting for build to complete..."
aws codebuild batch-get-builds \
    --ids $BUILD_ID \
    --region $REGION \
    --query 'builds[0].buildStatus' \
    --output text