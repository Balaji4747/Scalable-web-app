# Scalable Web Application Infrastructure

A complete DevOps solution with Infrastructure as Code, CI/CD, monitoring, and security best practices.

## Architecture Overview

- **Infrastructure**: AWS VPC with public/private subnets across 2 AZs
- **Application**: Containerized Node.js app with PostgreSQL database
- **Orchestration**: ECS with Fargate
- **CI/CD**: GitHub Actions pipeline
- **Monitoring**: CloudWatch metrics, logs, and alarms

## Quick Start

1. **Prerequisites**
   ```bash
   # Install required tools
   aws configure
   terraform --version
   docker --version
   ```

2. **Deploy Infrastructure**
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```

3. **Deploy Application**
   ```bash
   # Build and push container
   ./scripts/build-and-deploy.sh
   ```

## Project Structure

```
├── terraform/           # Infrastructure as Code
├── app/                # Application code
├── .github/workflows/  # CI/CD pipelines
├── scripts/            # Deployment scripts
└── docs/              # Documentation
```

## Components

- [Infrastructure Setup](terraform/README.md)
- [Application Deployment](app/README.md)
- [CI/CD Pipeline](.github/workflows/README.md)
- [Monitoring Setup](docs/monitoring.md)

## Security Features

- Private subnets for application and database
- Security groups with least privilege access
- Secrets management with AWS Secrets Manager
- Container image scanning