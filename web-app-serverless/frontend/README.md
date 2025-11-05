# Frontend Infrastructure (S3 + CloudFront)

This directory provisions the frontend stack for a static web app: a private S3 bucket for assets and a CloudFront distribution using Origin Access Control (OAC). It also supports an ALB origin under `/api/*` and associates a Lambda@Edge for viewer-request authentication.

## Directory structure
```
├── main.tf          # calls modules/s3 and modules/cloudfront
├── modules
│   ├── cloudfront   # CloudFront distribution + OAC + ALB origin + Lambda@Edge assoc
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── s3           # Private S3 bucket + policy + static file upload
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
├── outputs.tf
└── variables.tf
```

## What it creates
- Private S3 bucket for static content; public access blocked.
- CloudFront distribution with:
	- S3 as default origin with OAC and HTTPS-only.
	- ALB as secondary origin for `/api/*`.
	- Optional default root object.
	- Lambda@Edge association for viewer-request (auth gateway).
- Bucket policy allowing only the CloudFront distribution to read objects.
- Upload of all files from `web-ec2-scenario/files/` into the S3 bucket (paths preserved).

## Inputs (variables)
- `region` (string): AWS region for S3 and ancillary resources.
- `project_name` (string): Prefix for names and tags.
- `tags` (map(string)): Common tags.
- `cloudfront_price_class` (string): PriceClass_100 | PriceClass_200 | PriceClass_All.
- `default_root_object` (string): e.g., `index.html`.
- `cloudfront_alias` (string): Optional CNAME wired through root module; in the CloudFront module, aliases are currently commented out.
- `alb_domain_name` (string): ALB domain for API origin routing.
- `lambda_edge_arn` (string): Qualified Lambda@Edge version ARN for viewer-request.

## Outputs
- `s3_bucket_id`: S3 bucket ID.
- `s3_bucket_arn`: S3 bucket ARN.
- `cloudfront_domain_name`: CloudFront distribution domain.

## How to deploy
Run Terraform from the parent `web-ec2-scenario` stack so dependencies wire up correctly.

```sh
terraform init
terraform plan
terraform apply
```

Notes
- Static files are uploaded from `web-ec2-scenario/files/` via `aws_s3_object` (recursive). Update that folder and re-apply to sync assets.
- CloudFront changes may take several minutes to propagate.
- Lambda@Edge must be deployed in us-east-1; pass its qualified version ARN via `lambda_edge_arn`.
