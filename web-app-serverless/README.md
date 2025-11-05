# Serverless Web Application

A comprehensive AWS serverless web application infrastructure deployed with Terraform. This solution provides a scalable, secure, and monitored serverless architecture with integrated authentication, monitoring, and security services.

## 🏗️ Architecture Overview

```
CloudFront → Lambda@Edge (Auth) → S3 (Static Files)
                                ↓
                            API Gateway → Lambda (VPC) → RDS Proxy → MySQL RDS
                                ↓                ↓
                           Cognito (Auth)   VPC Endpoints (Private)
```

### Core Components

- **Frontend**: CloudFront distribution with S3 origin for static content
- **Authentication**: Lambda@Edge for request-level auth + Cognito User Pool
- **Backend API**: API Gateway with Lambda functions deployed in private VPC subnets
- **Database**: RDS MySQL with RDS Proxy for connection pooling in private subnets
- **Private Connectivity**: VPC endpoints for AWS services (Lambda, Secrets Manager, RDS)
- **Monitoring**: CloudWatch dashboards, alarms, and X-Ray distributed tracing
- **Security**: GuardDuty threat detection and KMS encryption
- **Networking**: VPC with private subnets across multiple AZs for high availability

### 🔒 Private Network Architecture

The entire backend infrastructure operates within private subnets with no direct internet access:

1. **API Gateway** → **Lambda (Private VPC)**: Uses AWS_PROXY integration over AWS private network
2. **Lambda** → **RDS Proxy**: Direct VPC communication over port 3306
3. **Lambda** → **AWS Services**: Via VPC endpoints (Secrets Manager, RDS service, Lambda service)
4. **RDS Proxy** → **Aurora MySQL**: Private subnet communication
5. **Monitoring**: X-Ray tracing and CloudWatch logs via VPC endpoints

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- PowerShell (for Windows) or Bash (for Linux/macOS)

### 1. Clone and Navigate

```bash
git clone <repository-url>
cd web-app-serverless
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Deploy infrastructure
terraform apply
```

### 4. Access Your Application

After successful deployment, you'll receive output with:

- **CloudFront URL**: Your web application endpoint
- **API Gateway URL**: Direct API access
- **CloudWatch Dashboard**: Monitoring and metrics
- **Cognito User Pool**: User management console

## 📋 Modules

### Backend (`./backend`)
- **VPC**: Private networking with 2+ subnets across AZs + VPC endpoints for AWS services
- **Lambda**: Serverless compute with X-Ray tracing deployed in private subnets
- **API Gateway**: REST API with Cognito authorization using AWS_PROXY integration
- **RDS**: MySQL database with AWS managed passwords in private subnets
- **RDS Proxy**: Connection pooling in private subnets
- **Cognito**: User authentication and authorization
- **CloudWatch**: Monitoring, dashboards, and alarms
- **X-Ray**: Distributed tracing and performance insights (private connectivity)
- **GuardDuty**: Security threat detection
- **S3**: Object storage for application data
- **VPC Endpoints**: Private access to Lambda, Secrets Manager, RDS services

### Frontend (`./frontend`)
- **S3**: Static website hosting
- **CloudFront**: Global CDN with caching
- **Origin Access Control**: Secure S3 access

### Lambda@Edge (`./lambda_edge`)
- **Authentication**: Request-level auth enforcement
- **PKCE Flow**: Secure OAuth 2.0 implementation
- **Edge Computing**: Low-latency auth processing

## 🔧 Configuration

### Environment Variables

The Lambda functions automatically receive:

- `DB_PROXY_ENDPOINT`: RDS Proxy connection string
- `DB_SECRET_ARN`: AWS Secrets Manager secret ARN
- `COGNITO_USER_POOL_ID`: User pool identifier
- `COGNITO_CLIENT_ID`: App client identifier

### Authentication Flow

1. **Unauthenticated Request** → Lambda@Edge → Cognito login redirect
2. **Authentication** → Cognito OAuth 2.0 PKCE flow
3. **Callback** → JWT token validation → Access granted
4. **API Requests** → JWT verification → Lambda execution

### Database Access

- **Connection Pooling**: RDS Proxy manages connections
- **Security**: AWS Secrets Manager for credentials
- **High Availability**: Multi-AZ deployment support
- **Encryption**: At rest and in transit

## 📊 Monitoring & Observability

### CloudWatch Dashboard

Pre-configured dashboards monitoring:

- **Lambda**: Duration, errors, invocations, throttles
- **API Gateway**: Request count, latency, 4XX/5XX errors
- **RDS**: CPU utilization, connections, memory, latency

### Alarms & Notifications

Automatic alerts for:

- Lambda function errors > 5 in 10 minutes
- Lambda duration > 30 seconds
- API Gateway 5XX errors
- High API latency
- RDS CPU > 80%
- Low RDS memory

### X-Ray Tracing

- **Service Map**: Visual application topology
- **Trace Analysis**: End-to-end request tracking
- **Performance Insights**: Bottleneck identification

### GuardDuty Security

- **Threat Detection**: Malicious activity monitoring
- **S3 Protection**: Data access anomaly detection
- **CloudWatch Integration**: Security event alerts

## 🔒 Security Features

### Network Security
- **VPC Isolation**: Private subnets for all compute resources (Lambda, RDS)
- **VPC Endpoints**: Private access to AWS services (Lambda, Secrets Manager, RDS, S3)
- **Security Groups**: Least-privilege access control with port 3306 (MySQL) and 443 (HTTPS)
- **No Internet Access**: Lambda functions operate entirely within private network
- **API Gateway Integration**: Uses AWS_PROXY over AWS private backbone (not internet)

### Data Security
- **Encryption**: KMS encryption for all data at rest
- **Secrets Management**: AWS Secrets Manager for credentials
- **SSL/TLS**: Encryption in transit for all communications

### Access Control
- **Cognito Integration**: Centralized user management
- **JWT Tokens**: Stateless authentication
- **IAM Roles**: Fine-grained service permissions

## 💰 Cost Optimization

### Development Environment
- **NAT Gateway**: Disabled by default (~$0/month)
- **RDS Instance**: db.t3.micro for development
- **CloudFront**: PriceClass_100 (US, Canada, Europe)

### Production Recommendations
- **NAT Gateway**: Enable for Lambda internet access (~$45/month)
- **RDS Instance**: Scale based on workload requirements
- **CloudFront**: Consider PriceClass_All for global coverage

## 🔄 CI/CD Integration

### GitHub Actions (Recommended)

```yaml
name: Deploy Serverless App
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
      - run: terraform init
      - run: terraform plan
      - run: terraform apply -auto-approve
```

## 🛠️ Development

### Local Development

1. **Frontend Development**:
   ```bash
   cd frontend/files
   # Serve static files locally
   python -m http.server 8000
   ```

2. **API Testing**:
   ```bash
   # Test API endpoints
   curl -H "Authorization: Bearer <jwt-token>" \
        https://your-api-id.execute-api.region.amazonaws.com/dev/api/users
   ```



## 🆘 Troubleshooting

### Common Issues

1. **Database Connection Errors**:
   - Check RDS Proxy configuration
   - Verify security group rules
   - Review Secrets Manager access

2. **CloudFront 403 Errors**:
   - Check S3 bucket policy
   - Verify Origin Access Control configuration

3. **Authentication Issues**:
   - Validate Cognito User Pool configuration
   - Check Lambda@Edge logs in CloudWatch
   - Verify JWT token format and expiration

### Monitoring Locations

- **Lambda Logs**: `/aws/lambda/function-name`
- **Lambda@Edge Logs**: `/aws/lambda/us-east-1.lambda-auth-edge`
- **API Gateway Logs**: `/aws/apigateway/your-api-name`
- **X-Ray Traces**: AWS X-Ray Console → Service Map


