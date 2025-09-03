#!/bin/bash

# Get ECR repository URL
ECR_REPO=$(terraform -chdir=../terraform output -raw ecr_repository_url)
REGION=$(terraform -chdir=../terraform output -raw aws_region)

echo "🚀 Starting deployment..."

# Login to ECR
echo "📦 Logging into ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REPO

# Build and push Docker image
echo "🔨 Building Docker image..."
docker build -t scalable-web-app ../app/

echo "📤 Pushing to ECR..."
docker tag scalable-web-app:latest $ECR_REPO:latest
docker push $ECR_REPO:latest

# Update ECS service
echo "🔄 Updating ECS service..."
aws ecs update-service \
  --cluster scalable-web-app-cluster \
  --service scalable-web-app-app-service \
  --force-new-deployment \
  --region $REGION

# Wait for deployment
echo "⏳ Waiting for deployment to complete..."
aws ecs wait services-stable \
  --cluster scalable-web-app-cluster \
  --services scalable-web-app-app-service \
  --region $REGION

# Get application URL
ALB_URL=$(terraform -chdir=../terraform output -raw alb_dns_name)
echo "✅ Deployment complete!"
echo "🌐 Your app is available at: http://$ALB_URL"
echo "🏥 Health check: http://$ALB_URL/health"