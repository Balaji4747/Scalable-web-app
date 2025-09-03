# Architecture Documentation

## System Overview

The Scalable Web Application is designed as a cloud-native, containerized solution deployed on AWS with high availability, security, and scalability in mind.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                          Internet                                │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                 Application Load Balancer                       │
│                    (Public Subnets)                            │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                  ECS Fargate Tasks                              │
│                  (Private Subnets)                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │   Task 1    │  │   Task 2    │  │   Task N    │            │
│  │ Node.js App │  │ Node.js App │  │ Node.js App │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                RDS PostgreSQL                                   │
│              (Private Subnets)                                 │
│         Primary + Multi-AZ Standby                             │
└─────────────────────────────────────────────────────────────────┘
```

## Network Architecture

### VPC Design
- **CIDR Block**: 10.0.0.0/16
- **Availability Zones**: 2 AZs for high availability
- **Subnets**: Public, Private, and Database subnets

### Subnet Layout
```
┌─────────────────────────────────────────────────────────────────┐
│                        VPC (10.0.0.0/16)                       │
│                                                                 │
│  AZ-1a                           AZ-1b                         │
│  ┌─────────────────┐             ┌─────────────────┐           │
│  │ Public Subnet   │             │ Public Subnet   │           │
│  │ 10.0.1.0/24     │             │ 10.0.2.0/24     │           │
│  │ - ALB           │             │ - ALB           │           │
│  │ - NAT Gateway   │             │ - NAT Gateway   │           │
│  │ - Bastion Host  │             │                 │           │
│  └─────────────────┘             └─────────────────┘           │
│                                                                 │
│  ┌─────────────────┐             ┌─────────────────┐           │
│  │ Private Subnet  │             │ Private Subnet  │           │
│  │ 10.0.3.0/24     │             │ 10.0.4.0/24     │           │
│  │ - ECS Tasks     │             │ - ECS Tasks     │           │
│  └─────────────────┘             └─────────────────┘           │
│                                                                 │
│  ┌─────────────────┐             ┌─────────────────┐           │
│  │ Database Subnet │             │ Database Subnet │           │
│  │ 10.0.5.0/24     │             │ 10.0.6.0/24     │           │
│  │ - RDS Primary   │             │ - RDS Standby   │           │
│  └─────────────────┘             └─────────────────┘           │
└─────────────────────────────────────────────────────────────────┘
```

## Security Architecture

### Security Groups
1. **ALB Security Group**
   - Inbound: HTTP (80), HTTPS (443) from 0.0.0.0/0
   - Outbound: All traffic

2. **ECS Security Group**
   - Inbound: Port 3000 from ALB SG, SSH from Bastion SG
   - Outbound: All traffic

3. **RDS Security Group**
   - Inbound: Port 5432 from ECS SG and Bastion SG
   - Outbound: None

4. **Bastion Security Group**
   - Inbound: SSH (22) from allowed CIDR blocks
   - Outbound: All traffic

### Network Access Control
- **Internet Gateway**: Public subnet internet access
- **NAT Gateways**: Private subnet outbound internet access
- **Route Tables**: Proper routing for each subnet type
- **NACLs**: Default allow (Security Groups provide primary security)

## Application Architecture

### Container Design
```
┌─────────────────────────────────────────────────────────────────┐
│                      ECS Task Definition                        │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                  Node.js Container                      │   │
│  │                                                         │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │   │
│  │  │   Express   │  │ PostgreSQL  │  │ CloudWatch  │    │   │
│  │  │   Server    │  │   Client    │  │   Logging   │    │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘    │   │
│  │                                                         │   │
│  │  Resources: 256 CPU, 512 MB Memory                     │   │
│  │  Port: 3000                                             │   │
│  │  Health Check: /health                                  │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Service Discovery
- **ALB Target Groups**: Automatic service discovery
- **ECS Service**: Manages task lifecycle and health
- **Auto Scaling**: CPU and memory-based scaling

## Data Architecture

### Database Design
```sql
-- Users Table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Posts Table
CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    content TEXT,
    user_id INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Database Configuration
- **Engine**: PostgreSQL 15.4
- **Instance Class**: db.t3.micro (configurable)
- **Storage**: GP3 SSD with auto-scaling
- **Backup**: 7-day retention with automated backups
- **Encryption**: At-rest encryption enabled
- **Multi-AZ**: Enabled for high availability

## Deployment Architecture

### CI/CD Pipeline
```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Source    │    │    Test     │    │    Build    │    │   Deploy    │
│             │    │             │    │             │    │             │
│ - Git Push  │───▶│ - Unit Test │───▶│ - Docker    │───▶│ - Staging   │
│ - PR Merge  │    │ - Security  │    │ - Security  │    │ - Production│
│             │    │   Audit     │    │   Scan      │    │             │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

### Deployment Strategy
1. **Blue-Green Deployment**: Zero-downtime deployments
2. **Rolling Updates**: Gradual task replacement
3. **Health Checks**: Ensure new tasks are healthy before routing traffic
4. **Rollback**: Automatic rollback on deployment failure

## Monitoring Architecture

### Observability Stack
```
┌─────────────────────────────────────────────────────────────────┐
│                      CloudWatch                                 │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │   Metrics   │  │    Logs     │  │   Alarms    │            │
│  │             │  │             │  │             │            │
│  │ - ECS       │  │ - App Logs  │  │ - CPU > 80% │            │
│  │ - ALB       │  │ - Access    │  │ - Memory    │            │
│  │ - RDS       │  │ - Error     │  │ - Response  │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   Dashboard                             │   │
│  │  - System Health    - Performance Metrics              │   │
│  │  - Error Rates      - Resource Utilization             │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                        SNS Alerts                               │
│                    Email Notifications                          │
└─────────────────────────────────────────────────────────────────┘
```

## Scalability Design

### Horizontal Scaling
- **ECS Auto Scaling**: 1-10 tasks based on CPU/Memory
- **ALB**: Automatically scales with traffic
- **RDS**: Read replicas for read scaling (future enhancement)

### Vertical Scaling
- **Task Resources**: Configurable CPU and memory
- **Database**: Instance class can be upgraded
- **Storage**: Auto-scaling storage for RDS

## High Availability

### Multi-AZ Design
- **ALB**: Deployed across multiple AZs
- **ECS Tasks**: Distributed across AZs
- **RDS**: Multi-AZ deployment with automatic failover
- **NAT Gateways**: One per AZ for redundancy

### Fault Tolerance
- **Health Checks**: Automatic unhealthy task replacement
- **Auto Scaling**: Maintains desired capacity
- **Database Backups**: Point-in-time recovery
- **Load Balancing**: Traffic distribution and failover

## Security Considerations

### Defense in Depth
1. **Network Security**: VPC, Security Groups, NACLs
2. **Application Security**: Container security, secrets management
3. **Data Security**: Encryption at rest and in transit
4. **Access Control**: IAM roles and policies
5. **Monitoring**: CloudTrail, VPC Flow Logs

### Compliance
- **Encryption**: All data encrypted at rest and in transit
- **Audit Logging**: CloudTrail for API calls
- **Access Logging**: ALB and application logs
- **Secrets Management**: AWS Secrets Manager for credentials

## Performance Optimization

### Application Level
- **Connection Pooling**: PostgreSQL connection pool
- **Caching**: In-memory caching (future enhancement)
- **Compression**: Gzip compression for responses
- **Health Checks**: Lightweight health endpoints

### Infrastructure Level
- **CDN**: CloudFront for static assets (future enhancement)
- **Database**: Optimized queries and indexing
- **Container**: Multi-stage Docker builds
- **Network**: Placement in private subnets

## Cost Optimization

### Resource Efficiency
- **Right-sizing**: Appropriate instance sizes
- **Auto Scaling**: Scale down during low usage
- **Reserved Capacity**: For predictable workloads
- **Spot Instances**: For development environments

### Monitoring Costs
- **CloudWatch**: Monitor log retention and metrics
- **Data Transfer**: Optimize cross-AZ traffic
- **Storage**: Lifecycle policies for backups
- **Unused Resources**: Regular cleanup and optimization