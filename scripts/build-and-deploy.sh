#!/bin/bash

# Build and Deploy Script for Scalable Web Application
set -e

# Configuration
PROJECT_NAME="scalable-web-app"
AWS_REGION="us-west-2"
ECR_REPOSITORY="${PROJECT_NAME}-app"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed"
        exit 1
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured"
        exit 1
    fi
    
    log_info "Prerequisites check passed"
}

deploy_infrastructure() {
    log_info "Deploying infrastructure with Terraform..."
    
    cd terraform
    
    # Initialize Terraform
    terraform init
    
    # Plan deployment
    terraform plan -out=tfplan
    
    # Apply deployment
    terraform apply tfplan
    
    # Get outputs
    ECR_URL=$(terraform output -raw ecr_repository_url)
    ALB_DNS=$(terraform output -raw alb_dns_name)
    
    cd ..
    
    log_info "Infrastructure deployed successfully"
    log_info "ECR Repository: $ECR_URL"
    log_info "Application URL: http://$ALB_DNS"
}

build_and_push_image() {
    log_info "Building and pushing Docker image..."
    
    # Get ECR login token
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URL
    
    cd app
    
    # Build Docker image
    docker build -t $ECR_REPOSITORY:latest .
    docker tag $ECR_REPOSITORY:latest $ECR_URL:latest
    docker tag $ECR_REPOSITORY:latest $ECR_URL:$(git rev-parse --short HEAD)
    
    # Push images
    docker push $ECR_URL:latest
    docker push $ECR_URL:$(git rev-parse --short HEAD)
    
    cd ..
    
    log_info "Docker image built and pushed successfully"
}

update_ecs_service() {
    log_info "Updating ECS service..."
    
    # Force new deployment
    aws ecs update-service \
        --cluster "${PROJECT_NAME}-cluster" \
        --service "${PROJECT_NAME}-app-service" \
        --force-new-deployment \
        --region $AWS_REGION
    
    # Wait for deployment to complete
    log_info "Waiting for deployment to complete..."
    aws ecs wait services-stable \
        --cluster "${PROJECT_NAME}-cluster" \
        --services "${PROJECT_NAME}-app-service" \
        --region $AWS_REGION
    
    log_info "ECS service updated successfully"
}

run_health_checks() {
    log_info "Running health checks..."
    
    # Get ALB DNS name
    ALB_DNS=$(aws elbv2 describe-load-balancers \
        --names "${PROJECT_NAME}-alb" \
        --query 'LoadBalancers[0].DNSName' \
        --output text \
        --region $AWS_REGION)
    
    # Wait for service to be ready
    sleep 30
    
    # Test health endpoint
    for i in {1..10}; do
        if curl -f "http://$ALB_DNS/health" &> /dev/null; then
            log_info "Health check passed"
            break
        else
            log_warn "Health check failed, retrying in 10 seconds... ($i/10)"
            sleep 10
        fi
        
        if [ $i -eq 10 ]; then
            log_error "Health checks failed after 10 attempts"
            exit 1
        fi
    done
    
    # Test API endpoints
    curl -f "http://$ALB_DNS/api/users" &> /dev/null || (log_error "Users API test failed" && exit 1)
    curl -f "http://$ALB_DNS/api/posts" &> /dev/null || (log_error "Posts API test failed" && exit 1)
    
    log_info "All health checks passed"
    log_info "Application is available at: http://$ALB_DNS"
}

cleanup() {
    log_info "Cleaning up..."
    
    # Remove local Docker images
    docker rmi $ECR_REPOSITORY:latest 2>/dev/null || true
    docker system prune -f
    
    log_info "Cleanup completed"
}

# Main execution
main() {
    log_info "Starting deployment process..."
    
    check_prerequisites
    
    case "${1:-all}" in
        "infra")
            deploy_infrastructure
            ;;
        "app")
            build_and_push_image
            update_ecs_service
            run_health_checks
            ;;
        "all")
            deploy_infrastructure
            build_and_push_image
            update_ecs_service
            run_health_checks
            ;;
        "cleanup")
            cleanup
            ;;
        *)
            log_error "Usage: $0 {infra|app|all|cleanup}"
            exit 1
            ;;
    esac
    
    log_info "Deployment process completed successfully!"
}

# Trap to cleanup on exit
trap cleanup EXIT

# Run main function
main "$@"