#!/bin/bash

# Destroy Infrastructure Script
set -e

# Configuration
PROJECT_NAME="scalable-web-app"
AWS_REGION="us-west-2"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

confirm_destruction() {
    log_warn "This will destroy ALL infrastructure resources!"
    log_warn "This action cannot be undone!"
    
    read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirmation
    
    if [ "$confirmation" != "yes" ]; then
        log_info "Destruction cancelled"
        exit 0
    fi
}

cleanup_ecr_images() {
    log_info "Cleaning up ECR images..."
    
    # List and delete all images in ECR repository
    aws ecr list-images \
        --repository-name "${PROJECT_NAME}-app" \
        --region $AWS_REGION \
        --query 'imageIds[*]' \
        --output json > /tmp/ecr_images.json
    
    if [ -s /tmp/ecr_images.json ] && [ "$(cat /tmp/ecr_images.json)" != "[]" ]; then
        aws ecr batch-delete-image \
            --repository-name "${PROJECT_NAME}-app" \
            --region $AWS_REGION \
            --image-ids file:///tmp/ecr_images.json
        log_info "ECR images deleted"
    else
        log_info "No ECR images to delete"
    fi
    
    rm -f /tmp/ecr_images.json
}

destroy_terraform() {
    log_info "Destroying Terraform infrastructure..."
    
    cd terraform
    
    # Initialize Terraform
    terraform init
    
    # Plan destruction
    terraform plan -destroy -out=destroy.tfplan
    
    # Apply destruction
    terraform apply destroy.tfplan
    
    # Clean up Terraform files
    rm -f destroy.tfplan
    rm -f tfplan
    rm -f terraform.tfstate.backup
    
    cd ..
    
    log_info "Terraform infrastructure destroyed"
}

cleanup_local_resources() {
    log_info "Cleaning up local resources..."
    
    # Remove Docker images
    docker rmi "${PROJECT_NAME}-app:latest" 2>/dev/null || true
    docker system prune -f
    
    log_info "Local cleanup completed"
}

main() {
    log_info "Starting infrastructure destruction..."
    
    confirm_destruction
    
    cleanup_ecr_images
    destroy_terraform
    cleanup_local_resources
    
    log_info "Infrastructure destruction completed successfully!"
    log_warn "All AWS resources have been destroyed"
}

main "$@"