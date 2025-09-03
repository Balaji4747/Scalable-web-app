#!/bin/bash

# Create deployment package
zip -r app-source.zip app/ buildspec.yml

# Upload to S3 (you'll need to create a bucket)
BUCKET_NAME="scalable-web-app-source-$(date +%s)"
aws s3 mb s3://$BUCKET_NAME --region us-west-2
aws s3 cp app-source.zip s3://$BUCKET_NAME/

# Start build with S3 source
aws codebuild start-build \
  --project-name scalable-web-app-build \
  --source-type-override S3 \
  --source-location-override $BUCKET_NAME/app-source.zip \
  --region us-west-2 \
  --output text

echo "Build started with S3 source: s3://$BUCKET_NAME/app-source.zip"