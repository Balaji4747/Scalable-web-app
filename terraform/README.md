# Infrastructure as Code

This directory contains Terraform configurations to deploy a scalable web application infrastructure on AWS.

## Architecture

- **VPC**: Multi-AZ setup with public and private subnets
- **Load Balancer**: Application Load Balancer in public subnets
- **Compute**: ECS Fargate tasks in private subnets with auto-scaling
- **Database**: RDS PostgreSQL in private subnets
- **Security**: Security groups with least privilege access
- **Monitoring**: CloudWatch dashboards, alarms, and centralized logging

## Prerequisites

1. **AWS CLI configured**
   ```bash
   aws configure
   ```

2. **Terraform installed** (>= 1.0)
   ```bash
   terraform --version
   ```

3. **SSH Key Pair**
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/scalable-web-app
   ```

## Deployment

1. **Copy and customize variables**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Plan deployment**
   ```bash
   terraform plan
   ```

4. **Deploy infrastructure**
   ```bash
   terraform apply
   ```

## Configuration

### Required Variables

- `public_key`: Your SSH public key for bastion access
- `db_password`: Secure password for RDS instance
- `allowed_ssh_cidrs`: Your IP address for SSH access

### Optional Variables

- `ssl_certificate_arn`: SSL certificate for HTTPS
- `alert_email`: Email for CloudWatch alerts
- `environment`: Environment name (dev/staging/production)

## Security Features

- **Network Isolation**: Private subnets for application and database
- **Bastion Host**: Secure SSH access to private resources
- **Security Groups**: Restrictive firewall rules
- **Secrets Management**: Database credentials in AWS Secrets Manager
- **Encryption**: RDS encryption at rest

## Monitoring

- **CloudWatch Dashboard**: Application and infrastructure metrics
- **Alarms**: CPU, memory, and response time monitoring
- **Centralized Logging**: ECS logs in CloudWatch Logs
- **SNS Alerts**: Email notifications for critical events

## Outputs

After deployment, Terraform outputs important information:

- `application_url`: URL to access your application
- `bastion_public_ip`: IP address of bastion host
- `ecr_repository_url`: ECR repository for container images
- `cloudwatch_dashboard_url`: Direct link to monitoring dashboard

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Troubleshooting

### Common Issues

1. **AMI not found**: Update `bastion_ami` variable for your region
2. **Insufficient permissions**: Ensure AWS credentials have required permissions
3. **Resource limits**: Check AWS service quotas in your region

### Useful Commands

```bash
# Check current state
terraform show

# Import existing resources
terraform import aws_vpc.main vpc-12345678

# Refresh state
terraform refresh

# Format code
terraform fmt -recursive
```