#!/usr/bin/env bash
set -euo pipefail

# Bootstrap the Terraform backend: S3 bucket (versioned, encrypted, private)
# and DynamoDB table for state locking.

BUCKET_NAME=${BUCKET_NAME:-test-practice-bucket-terraform-state}
BUCKET_REGION=${BUCKET_REGION:-eu-west-1}
TABLE_NAME=${TABLE_NAME:-terraform-state-locks}




echo "[+] Region:        $BUCKET_REGION"
echo "[+] Bucket name:   $BUCKET_NAME"
echo "[+] Lock table:    $TABLE_NAME"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: '$1' is required but not found in PATH." >&2
    exit 1
  fi
}

require_cmd aws

echo "[+] Ensuring S3 bucket exists..."
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
  echo "Bucket exists: $BUCKET_NAME"
else
  echo "Creating bucket: $BUCKET_NAME"
  aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$BUCKET_REGION" \
    --create-bucket-configuration LocationConstraint="$BUCKET_REGION"
fi

echo "[+] Enabling versioning..."
aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" --versioning-configuration Status=Enabled

echo "[+] Blocking public access..."
aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration 'BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true'

echo "[+] Enabling default SSE (AES256)..."
aws s3api put-bucket-encryption \
  --bucket "$BUCKET_NAME" \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

echo "[+] Ensuring DynamoDB lock table exists..."
if aws dynamodb describe-table --table-name "$TABLE_NAME" >/dev/null 2>&1; then
  echo "DynamoDB table exists: $TABLE_NAME"
else
  echo "Creating DynamoDB table: $TABLE_NAME"
  aws dynamodb create-table \
    --table-name "$TABLE_NAME" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST
  echo "Waiting for table to become ACTIVE..."
  aws dynamodb wait table-exists --table-name "$TABLE_NAME"
fi

cat <<EONOTE

[✓] Backend bootstrap complete.

Update (or verify) your Terraform backend configuration contains:

  bucket         = "$BUCKET_NAME"
  key            = "web-app-serverless/terraform.tfstate"
  region         = "$BUCKET_REGION"
  dynamodb_table = "$TABLE_NAME"

EONOTE
