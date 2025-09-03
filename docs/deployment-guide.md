# Deployment Guide

This guide provides step-by-step instructions for deploying the Scalable Web Application to AWS.

## Prerequisites

### Required Tools
1. **AWS CLI** (v2.0+)
   ```bash
   # Install AWS CLI
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   
   # Configure credentials
   aws configure
   ```

2. **Terraform** (v1.0+)
   ```bash
   # Install Terraform
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

3. **Docker** (v20.0+)
   ```bash
   # Install Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sh get-docker.sh
   sudo usermod -aG docker $USER
   ```

4. **Git**
   ```bash
   sudo apt-get update
   sudo apt-get install git
   ```

### AWS Account Setup
1. **IAM User**: Create IAM user with programmatic access
2. **Permissions**: Attach the following policies:
   - `AmazonEC2FullAccess`
   - `AmazonECSFullAccess`
   - `AmazonRDSFullAccess`
   - `AmazonVPCFullAccess`
   - `ElasticLoadBalancingFullAccess`
   - `CloudWatchFullAccess`
   - `IAMFullAccess`
   - `AmazonEC2ContainerRegistryFullAccess`

3. **SSH Key Pair**: Generate SSH key for bastion host access
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/scalable-web-app
   ```

## Deployment Methods

### Method 1: Automated Script Deployment

1. **Clone Repository**
   ```bash
   git clone <repository-url>
   cd scalable-web-app
   ```

2. **Configure Variables**
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Run Deployment Script**
   ```bash
   chmod +x scripts/build-and-deploy.sh
   ./scripts/build-and-deploy.sh all
   ```

### Method 2: Manual Step-by-Step Deployment

#### Step 1: Infrastructure Deployment

1. **Navigate to Terraform directory**
   ```bash
   cd terraform
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Create terraform.tfvars**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

4. **Edit terraform.tfvars** with your configuration:
   ```hcl
   # Required variables
   project_name = "scalable-web-app"
   environment = "production"
   aws_region = "us-west-2"
   
   # Network configuration
   vpc_cidr = "10.0.0.0/16"
   public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
   private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
   database_subnet_cidrs = ["10.0.5.0/24", "10.0.6.0/24"]
   
   # Security configuration
   allowed_ssh_cidrs = ["YOUR_IP/32"]
   public_key = "ssh-rsa AAAAB3NzaC1yc2E..."
   
   # Database configuration
   db_password = "SecurePassword123!"
   db_instance_class = "db.t3.micro"
   
   # Monitoring
   alert_email = "your-email@example.com"
   ```

5. **Plan and Apply**
   ```bash
   terraform plan
   terraform apply
   ```

6. **Note the outputs**
   ```bash
   terraform output
   ```

#### Step 2: Application Deployment

1. **Get ECR login**
   ```bash
   aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <ecr-url>
   ```

2. **Build and push Docker image**
   ```bash
   cd ../app
   
   # Build image
   docker build -t scalable-web-app .
   
   # Tag for ECR
   docker tag scalable-web-app:latest <ecr-url>:latest
   
   # Push to ECR
   docker push <ecr-url>:latest
   ```

3. **Update ECS service**
   ```bash
   aws ecs update-service \
     --cluster scalable-web-app-cluster \
     --service scalable-web-app-app-service \
     --force-new-deployment
   ```

4. **Wait for deployment**
   ```bash
   aws ecs wait services-stable \
     --cluster scalable-web-app-cluster \
     --services scalable-web-app-app-service
   ```

## Configuration Options

### Environment-Specific Configurations

#### Development Environment
```hcl
environment = "dev"
db_instance_class = "db.t3.micro"
ecs_desired_count = 1
ecs_min_capacity = 1
ecs_max_capacity = 3
log_retention_days = 7
```

#### Staging Environment
```hcl
environment = "staging"
db_instance_class = "db.t3.small"
ecs_desired_count = 2
ecs_min_capacity = 1
ecs_max_capacity = 5
log_retention_days = 14
```

#### Production Environment
```hcl
environment = "production"
db_instance_class = "db.t3.medium"
ecs_desired_count = 3
ecs_min_capacity = 2
ecs_max_capacity = 10
log_retention_days = 30
db_backup_retention_period = 30
```

### Security Configurations

#### SSL Certificate Setup
1. **Request certificate in ACM**
   ```bash
   aws acm request-certificate \
     --domain-name yourdomain.com \
     --validation-method DNS
   ```

2. **Add certificate ARN to terraform.tfvars**
   ```hcl
   ssl_certificate_arn = "arn:aws:acm:region:account:certificate/cert-id"
   ```

#### Custom Domain Setup
1. **Create Route 53 hosted zone**
2. **Create ALIAS record pointing to ALB**
3. **Update security groups if needed**

## Verification Steps

### 1. Infrastructure Verification
```bash
# Check VPC
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=scalable-web-app-vpc"

# Check ECS cluster
aws ecs describe-clusters --clusters scalable-web-app-cluster

# Check RDS instance
aws rds describe-db-instances --db-instance-identifier scalable-web-app-database

# Check ALB
aws elbv2 describe-load-balancers --names scalable-web-app-alb
```

### 2. Application Verification
```bash
# Get ALB DNS name
ALB_DNS=$(terraform output -raw alb_dns_name)

# Test health endpoint
curl http://$ALB_DNS/health

# Test API endpoints
curl http://$ALB_DNS/api/users
curl http://$ALB_DNS/api/posts

# Test database connectivity
curl http://$ALB_DNS/api/db-status
```

### 3. Monitoring Verification
```bash
# Check CloudWatch dashboard
aws cloudwatch get-dashboard --dashboard-name scalable-web-app-dashboard

# Check alarms
aws cloudwatch describe-alarms --alarm-names scalable-web-app-high-cpu

# Check logs
aws logs describe-log-groups --log-group-name-prefix /ecs/scalable-web-app
```

## Troubleshooting

### Common Issues

#### 1. Terraform Apply Fails
```bash
# Check AWS credentials
aws sts get-caller-identity

# Check permissions
aws iam get-user

# Validate Terraform configuration
terraform validate

# Check for resource conflicts
terraform plan
```

#### 2. ECS Tasks Not Starting
```bash
# Check ECS service events
aws ecs describe-services --cluster scalable-web-app-cluster --services scalable-web-app-app-service

# Check task definition
aws ecs describe-task-definition --task-definition scalable-web-app-app

# Check CloudWatch logs
aws logs get-log-events --log-group-name /ecs/scalable-web-app-app --log-stream-name <stream-name>
```

#### 3. Database Connection Issues
```bash
# Check RDS status
aws rds describe-db-instances --db-instance-identifier scalable-web-app-database

# Check security groups
aws ec2 describe-security-groups --filters "Name=tag:Name,Values=scalable-web-app-rds-sg"

# Test from bastion host
ssh -i ~/.ssh/scalable-web-app ec2-user@<bastion-ip>
psql -h <rds-endpoint> -U dbadmin -d appdb
```

#### 4. Load Balancer Issues
```bash
# Check ALB status
aws elbv2 describe-load-balancers --names scalable-web-app-alb

# Check target group health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# Check security groups
aws ec2 describe-security-groups --filters "Name=tag:Name,Values=scalable-web-app-alb-sg"
```

## Rollback Procedures

### Application Rollback
```bash
# Rollback to previous task definition
aws ecs update-service \
  --cluster scalable-web-app-cluster \
  --service scalable-web-app-app-service \
  --task-definition scalable-web-app-app:<previous-revision>

# Wait for rollback to complete
aws ecs wait services-stable \
  --cluster scalable-web-app-cluster \
  --services scalable-web-app-app-service
```

### Infrastructure Rollback
```bash
# Revert to previous Terraform state
terraform plan -target=<resource> -destroy
terraform apply -target=<resource>

# Or restore from backup
terraform state pull > backup.tfstate
terraform state push backup.tfstate
```

## Cleanup

### Destroy Infrastructure
```bash
# Use cleanup script
./scripts/destroy-infrastructure.sh

# Or manual cleanup
cd terraform
terraform destroy
```

### Manual Resource Cleanup
```bash
# Delete ECR images
aws ecr list-images --repository-name scalable-web-app-app --query 'imageIds[*]' --output json > images.json
aws ecr batch-delete-image --repository-name scalable-web-app-app --image-ids file://images.json

# Delete CloudWatch logs
aws logs delete-log-group --log-group-name /ecs/scalable-web-app-app

# Delete S3 buckets (if any)
aws s3 rb s3://bucket-name --force
```

## Best Practices

### Security
- Use least privilege IAM policies
- Enable MFA for AWS accounts
- Rotate access keys regularly
- Use AWS Secrets Manager for sensitive data
- Enable CloudTrail for audit logging

### Cost Optimization
- Use appropriate instance sizes
- Enable auto-scaling
- Monitor and optimize resource usage
- Use reserved instances for predictable workloads
- Set up billing alerts

### Monitoring
- Set up comprehensive monitoring
- Configure meaningful alerts
- Use structured logging
- Monitor application performance
- Track business metrics

### Maintenance
- Regular security updates
- Database maintenance windows
- Backup verification
- Disaster recovery testing
- Documentation updates