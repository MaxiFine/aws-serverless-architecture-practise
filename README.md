# AWS Serverless Web App — Easy Deploy Guide

This repository deploys a complete serverless web application on AWS using Terraform. It sets up a secure, scalable backend API, authentication, database, static website hosting, monitoring, and security services for you.

## What gets created

- Frontend: S3 bucket for static files + CloudFront CDN
- Authentication: Amazon Cognito (user pool and app client)
- API: API Gateway → Lambda (inside a private VPC)
- Database: RDS (with RDS Proxy) in private subnets
- Observability: CloudWatch dashboards/alarms + AWS X-Ray
- Security: GuardDuty + encryption everywhere

You’ll get a CloudFront URL for the website and an API Gateway URL for the API after deployment.

## Before you start (once)

You’ll need:

1. An AWS account with permissions to create common services (IAM roles, VPC, S3, CloudFront, Lambda, API Gateway, RDS, Cognito, CloudWatch).
2. AWS CLI installed and configured with your credentials (any Admin-like account is easiest for testing).
3. Terraform v1.0+ installed.
4. Bash available (important): there are a couple of small “post-setup” steps that run shell commands. On Windows, please run Terraform from either:
	 - Git Bash (install Git for Windows), or
	 - Windows Subsystem for Linux (WSL), e.g., Ubuntu

PowerShell is fine for basic commands, but the automated post-steps use Bash. Running Terraform from Git Bash/WSL avoids cross-shell issues.

## Where to run commands

All Terraform commands must be run inside the `web-app-serverless` directory:

```
web-app-serverless/
	main.tf
	backend.tf (Terraform remote state)
	backend/
	frontend/
	lambda_edge/
	files/ (static website files)
```

## Pick your state option (remote vs local)

This project is set up to store Terraform state in an S3 bucket by default (remote state). You can:

- Option A — Use remote state (recommended): ensure the S3 bucket exists and you have access.
	- Bucket name: `learning-bucket-terraform-state`
	- Bucket region: `eu-west-1`
	- State key: `web-app-serverless/terraform.tfstate`

- Option B — Use local state (for quick tests): initialize Terraform with `-backend=false`. This skips the remote S3 backend and stores state locally in the folder.

## Quick deploy (step-by-step)

1) Clone and enter the folder

- Open Git Bash or WSL
- Clone your repo and change into the Terraform root folder:

```
git clone <your-repository-url>
cd serverless/web-app-serverless
```

2) (Optional) Create the S3 state bucket (only if using Option A and it doesn’t exist)

```
aws s3api create-bucket \
	--bucket learning-bucket-terraform-state \
	--region eu-west-1 \
	--create-bucket-configuration LocationConstraint=eu-west-1
```

3) Review/edit variables (optional)

- Defaults are safe for a test run. You can override values using `terraform.tfvars` or `-var` flags.
- Common settings live in `web-app-serverless/variables.tf` (e.g., `region`, `project_name`, `cloudfront_price_class`, `api_stage_name`, Cognito settings, DB settings).
- If you want to tweak backend-specific values, see `web-app-serverless/backend/variable.tf`.

4) Initialize Terraform

- Remote state (Option A):

```
terraform init
```

- Local state (Option B):

```
terraform init -backend=false
```

5) See the plan (what will be created)

```
terraform plan -out plan.tfplan
```

6) Apply (create everything)

```
terraform apply "plan.tfplan"
```

This takes a while. CloudFront and Lambda@Edge can take several minutes to finish.

7) Get your outputs (important URLs)

```
terraform output
```

Look for:

- `cloudfront_domain_name` → your website URL (e.g., https://dxxxxxxx.cloudfront.net)
- `api_gateway_invoke_url` → your API base URL
- `cloudwatch_dashboard_url` → link to your prebuilt dashboard

## View the site and test

- Open the CloudFront URL in your browser. If it’s blank or errors, wait a couple of minutes (CloudFront propagation) and refresh.
- Some routes are protected by authentication (Cognito). The built-in Lambda@Edge will redirect unauthenticated users to sign in.

## Static files (website content)

- Place your site files (index.html, images, JS, CSS) in `web-app-serverless/files/` before applying.
- Re-run `terraform apply` to sync changes to S3 if you update files later.

## Troubleshooting (quick fixes)

- “Bucket for backend not found” during `terraform init`:
	- Create the `learning-bucket-terraform-state` bucket in `eu-west-1`, or use `terraform init -backend=false` for local state.

- Post-setup (Cognito callback update or API CORS update) failed:
	- Run Terraform from Git Bash/WSL so Bash is available, and ensure your AWS CLI is configured and authorized.

- CloudFront shows 403/404 or old content:
	- Wait a few minutes for distribution to deploy; ensure files exist under `web-app-serverless/files/` and re-apply.

- AccessDenied/permission errors:
	- Verify your AWS credentials and account permissions. Re-run `aws configure` if needed.

## Destroy (clean everything up)

When you’re finished testing, you can remove all resources Terraform created:

```
terraform destroy -auto-approve
```

If destroy reports a dependency error, wait a minute and run it again, or remove the named blocker in the AWS Console and retry.

## What’s inside (for the curious)

- Root module: `web-app-serverless/main.tf` wires together `backend`, `frontend`, and `lambda_edge` modules.
- Providers: `web-app-serverless/backend.tf` sets the AWS providers and remote state (S3) in `eu-west-1` and a `us-east-1` alias for Lambda@Edge.
- Outputs: after `apply`, check everything via `terraform output`.

That’s it — you can now deploy, view, and tear down the whole serverless stack with a handful of commands.

## Shortcut: use the helper scripts

Inside `web-app-serverless/` we added simple helpers that run the full flow and basic checks.

- Git Bash / WSL (Linux/macOS):

```
cd serverless/web-app-serverless
./deploy.sh                 # remote backend (S3) if available
./deploy.sh --local         # use local state (no S3 backend)
./deploy.sh --auto-approve  # non-interactive apply
./deploy.sh --destroy --auto-approve  # tear everything down
```

- Windows PowerShell (wrapper calls Bash internally):

```
Set-Location serverless/web-app-serverless
./deploy.ps1                # remote backend (S3) if available
./deploy.ps1 -Local         # use local state (no S3 backend)
./deploy.ps1 -AutoApprove   # non-interactive apply
./deploy.ps1 -Destroy -AutoApprove  # tear everything down
```

Note: The project runs a couple of post-steps that require Bash. Using Git Bash or WSL is recommended on Windows.

## Bootstrap remote state (bucket + lock table)

If `terraform init` fails because the S3 bucket doesn’t exist, create the backend bucket and DynamoDB lock table once. You have three options:

1) Quick local bootstrap (Git Bash/WSL):

```
cd serverless/web-app-serverless
./bootstrap-state.sh                       # uses defaults
BUCKET_NAME=my-unique-tf-state BUCKET_REGION=eu-west-1 TABLE_NAME=terraform-state-locks ./bootstrap-state.sh
```

2) Quick local bootstrap (PowerShell):

```
Set-Location serverless/web-app-serverless
./bootstrap-state.ps1                                  # uses defaults
./bootstrap-state.ps1 -BucketName my-unique-tf-state -BucketRegion eu-west-1 -TableName terraform-state-locks
```

3) GitHub Actions (recommended for teams):

- Configure an AWS role for GitHub OIDC and add its ARN to repository secret `AWS_ROLE_TO_ASSUME`.
- Run the workflow "Bootstrap Terraform Backend" from the Actions tab and provide:
	- bucket-name (must be globally unique)
	- aws-region (e.g., eu-west-1)
	- lock-table-name (e.g., terraform-state-locks)

Then update `web-app-serverless/backend.tf` if you changed names, ensuring it has:

```
backend "s3" {
	bucket         = "<your-bucket>"
	key            = "web-app-serverless/terraform.tfstate"
	region         = "<your-region>"
	dynamodb_table = "<your-lock-table>"
}
```

