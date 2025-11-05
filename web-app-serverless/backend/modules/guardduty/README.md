# GuardDuty SNS Email Alerts Configuration

## Overview
This GuardDuty module is configured to send real-time email notifications when security threats are detected in your AWS environment.

## How It Works

### 1. SNS Topic
- Creates an SNS topic named `{project_name}-guardduty-alerts`
- Configured with proper IAM policies to allow CloudWatch Events to publish messages

### 2. Email Subscription
- Automatically subscribes the configured email address to receive alerts
- Email address is configurable via the `guardduty_alerts_email` variable
- **Important**: You must confirm the subscription in your email inbox after deployment

### 3. CloudWatch Events Integration
- CloudWatch Events rule captures all GuardDuty findings
- Transforms the raw GuardDuty JSON into readable email format
- Includes key information: severity, type, description, account, region, and timestamp

### 4. Message Format
Email alerts include:
- **Severity**: High, Medium, Low
- **Finding Type**: Type of threat detected
- **Title**: Brief description of the finding
- **Description**: Detailed explanation
- **Account & Region**: Where the threat was detected
- **Time**: When the finding was created
- **Finding ID**: Unique identifier for tracking

## Configuration Variables

```hcl
enable_sns_notifications = true                           # Enable/disable email alerts
guardduty_alerts_email   = "maxwell.adomako@amalitech.com" # Email to receive alerts
```

## Post-Deployment Steps

1. **Confirm Email Subscription**
   - Check your email inbox for a subscription confirmation from AWS
   - Click the confirmation link to start receiving alerts

2. **Test the Setup**
   - You can test by creating a sample GuardDuty finding or waiting for real threats
   - Monitor the GuardDuty console for findings

## Email Alert Example

```
GuardDuty Alert: {
  "Severity": "8.5",
  "Finding Type": "UnauthorizedAccess:EC2/SSHBruteForce",
  "Title": "SSH brute force attacks against EC2 instance",
  "Description": "EC2 instance has been involved in SSH brute force attacks...",
  "Account": "123456789012",
  "Region": "eu-west-1", 
  "Time": "2024-01-15T10:30:00.000Z",
  "Finding ID": "12345678901234567890"
}
```

## Cost Considerations
- SNS email notifications are very cost-effective
- First 1,000 email notifications per month are free
- Additional emails cost $0.75 per 100,000 notifications
- CloudWatch Events rules are $1 per million events

## Security Features
- Messages are encrypted in transit
- SNS topic has restricted access policies
- Only CloudWatch Events from your account can publish
- Email alerts don't contain sensitive data, just threat summaries