Param(
  [string] $BucketName = 'learning-bucket-terraform-state',
  [string] $BucketRegion = 'eu-west-1',
  [string] $TableName = 'terraform-state-locks'
)

$ErrorActionPreference = 'Stop'

function Require-Command($name) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    throw "Command not found: $name. Please install it and try again."
  }
}

Require-Command aws

Write-Host "[+] Region:      $BucketRegion"
Write-Host "[+] Bucket:      $BucketName"
Write-Host "[+] Lock Table:  $TableName"

Write-Host "[+] Ensuring S3 bucket exists..."
try {
  aws s3api head-bucket --bucket $BucketName | Out-Null
  Write-Host "Bucket exists: $BucketName"
} catch {
  Write-Host "Creating bucket: $BucketName"
  aws s3api create-bucket `
    --bucket $BucketName `
    --region $BucketRegion `
    --create-bucket-configuration LocationConstraint=$BucketRegion | Out-Null
}

Write-Host "[+] Enabling versioning..."
aws s3api put-bucket-versioning --bucket $BucketName --versioning-configuration Status=Enabled | Out-Null

Write-Host "[+] Blocking public access..."
aws s3api put-public-access-block `
  --bucket $BucketName `
  --public-access-block-configuration 'BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true' | Out-Null

Write-Host "[+] Enabling default SSE (AES256)..."
aws s3api put-bucket-encryption `
  --bucket $BucketName `
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' | Out-Null

Write-Host "[+] Ensuring DynamoDB lock table exists..."
$tableExists = $false
try {
  aws dynamodb describe-table --table-name $TableName | Out-Null
  $tableExists = $true
} catch {
  $tableExists = $false
}

if (-not $tableExists) {
  Write-Host "Creating DynamoDB table: $TableName"
  aws dynamodb create-table `
    --table-name $TableName `
    --attribute-definitions AttributeName=LockID,AttributeType=S `
    --key-schema AttributeName=LockID,KeyType=HASH `
    --billing-mode PAY_PER_REQUEST | Out-Null

  Write-Host "Waiting for table to become ACTIVE..."
  aws dynamodb wait table-exists --table-name $TableName
} else {
  Write-Host "DynamoDB table exists: $TableName"
}

Write-Host ""
Write-Host "[✓] Backend bootstrap complete."
Write-Host ""
Write-Host "Update (or verify) your Terraform backend configuration contains:" -ForegroundColor Yellow
Write-Host "  bucket         = '$BucketName'"
Write-Host "  key            = 'web-app-serverless/terraform.tfstate'"
Write-Host "  region         = '$BucketRegion'"
Write-Host "  dynamodb_table = '$TableName'"
