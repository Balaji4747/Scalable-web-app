# Monitoring and Observability

This document describes the monitoring setup for the scalable web application.

## CloudWatch Dashboard

The application includes a comprehensive CloudWatch dashboard with the following metrics:

### ECS Service Metrics
- **CPU Utilization**: Average CPU usage across all tasks
- **Memory Utilization**: Average memory usage across all tasks
- **Task Count**: Number of running tasks

### Application Load Balancer Metrics
- **Request Count**: Total number of requests
- **Target Response Time**: Average response time
- **HTTP Status Codes**: 2XX, 4XX, 5XX response counts
- **Healthy Host Count**: Number of healthy targets

### RDS Database Metrics
- **CPU Utilization**: Database CPU usage
- **Database Connections**: Active connections
- **Freeable Memory**: Available memory
- **Read/Write IOPS**: Database I/O operations

## CloudWatch Alarms

### Critical Alarms
1. **High CPU Utilization** (>80%)
   - Triggers auto-scaling
   - Sends SNS notification

2. **High Memory Utilization** (>85%)
   - Triggers auto-scaling
   - Sends SNS notification

3. **High Response Time** (>2 seconds)
   - Indicates performance issues
   - Sends SNS notification

4. **RDS High CPU** (>75%)
   - Database performance concern
   - Sends SNS notification

### Warning Alarms
1. **Low Healthy Targets** (<50% of desired)
2. **High Error Rate** (>5% 5XX responses)
3. **Database Connection Limit** (>80% of max connections)

## Logging Strategy

### Application Logs
- **Location**: CloudWatch Logs Group `/ecs/scalable-web-app-app`
- **Retention**: 14 days (configurable)
- **Format**: JSON structured logs

### Log Types
1. **Access Logs**: HTTP requests (Morgan format)
2. **Application Logs**: Custom application events
3. **Error Logs**: Exceptions and errors
4. **Database Logs**: Query logs and connection events

### Log Aggregation
```javascript
// Example log structure
{
  "timestamp": "2023-10-01T12:00:00Z",
  "level": "info",
  "message": "User created successfully",
  "userId": 123,
  "requestId": "abc-123-def",
  "ip": "10.0.1.100"
}
```

## Health Checks

### Application Health Check
- **Endpoint**: `/health`
- **Frequency**: Every 30 seconds
- **Timeout**: 5 seconds
- **Healthy Threshold**: 2 consecutive successes
- **Unhealthy Threshold**: 2 consecutive failures

### Database Health Check
- **Endpoint**: `/api/db-status`
- **Tests**: Database connectivity and query execution
- **Used by**: Application monitoring and troubleshooting

### Load Balancer Health Check
- **Target**: ECS tasks on port 3000
- **Path**: `/health`
- **Interval**: 30 seconds
- **Timeout**: 5 seconds
- **Healthy/Unhealthy Threshold**: 2/2

## Auto Scaling Configuration

### ECS Service Auto Scaling
- **Metric**: CPU and Memory utilization
- **Target CPU**: 70%
- **Target Memory**: 80%
- **Scale Out**: Add 1 task when threshold exceeded for 2 minutes
- **Scale In**: Remove 1 task when below threshold for 5 minutes
- **Min Capacity**: 1 task
- **Max Capacity**: 10 tasks

### Scaling Policies
1. **CPU-based scaling**: Target 70% CPU utilization
2. **Memory-based scaling**: Target 80% memory utilization
3. **Custom metrics**: Request count per task (optional)

## Alerting

### SNS Topic Configuration
- **Topic Name**: `scalable-web-app-alerts`
- **Subscribers**: Email notifications
- **Message Format**: JSON with alarm details

### Alert Types
1. **Critical**: Immediate attention required
   - Service down
   - High error rates
   - Database connectivity issues

2. **Warning**: Monitor closely
   - High resource utilization
   - Slow response times
   - Scaling events

3. **Info**: Informational
   - Deployment events
   - Scaling activities
   - Maintenance windows

## Monitoring Best Practices

### 1. Golden Signals
- **Latency**: Response time monitoring
- **Traffic**: Request rate and patterns
- **Errors**: Error rate and types
- **Saturation**: Resource utilization

### 2. Custom Metrics
```javascript
// Example custom metric
const AWS = require('aws-sdk');
const cloudwatch = new AWS.CloudWatch();

const putMetric = async (metricName, value, unit = 'Count') => {
  const params = {
    Namespace: 'ScalableWebApp',
    MetricData: [{
      MetricName: metricName,
      Value: value,
      Unit: unit,
      Timestamp: new Date()
    }]
  };
  
  await cloudwatch.putMetricData(params).promise();
};
```

### 3. Dashboard Organization
- **Overview**: High-level system health
- **Application**: Application-specific metrics
- **Infrastructure**: AWS resource metrics
- **Business**: Business KPIs and user metrics

## Troubleshooting Guide

### High CPU Usage
1. Check CloudWatch metrics for CPU spikes
2. Review application logs for performance issues
3. Consider scaling up or optimizing code
4. Check for memory leaks

### High Response Times
1. Check database performance metrics
2. Review slow query logs
3. Analyze network latency
4. Consider caching strategies

### Database Issues
1. Monitor connection count
2. Check for long-running queries
3. Review database logs
4. Consider read replicas for scaling

### Container Issues
1. Check ECS service events
2. Review container logs
3. Verify health check configuration
4. Check resource limits

## Monitoring Tools Integration

### Third-party Tools (Optional)
- **Datadog**: Advanced APM and monitoring
- **New Relic**: Application performance monitoring
- **Grafana**: Custom dashboards and visualization
- **Prometheus**: Metrics collection and alerting

### AWS X-Ray Integration
```javascript
const AWSXRay = require('aws-xray-sdk-core');
const AWS = AWSXRay.captureAWS(require('aws-sdk'));

// Trace HTTP requests
app.use(AWSXRay.express.openSegment('ScalableWebApp'));
app.use(AWSXRay.express.closeSegment());
```

## Cost Monitoring

### CloudWatch Costs
- **Log Storage**: Monitor log retention and volume
- **Metrics**: Track custom metric usage
- **Alarms**: Optimize alarm configuration

### Resource Optimization
- **Right-sizing**: Monitor and adjust instance sizes
- **Reserved Capacity**: Consider reserved instances for predictable workloads
- **Spot Instances**: Use for non-critical workloads

## Security Monitoring

### CloudTrail Integration
- **API Calls**: Monitor AWS API usage
- **Access Patterns**: Track unusual access patterns
- **Compliance**: Audit trail for compliance requirements

### VPC Flow Logs
- **Network Traffic**: Monitor network patterns
- **Security Groups**: Validate firewall rules
- **Anomaly Detection**: Identify unusual traffic patterns