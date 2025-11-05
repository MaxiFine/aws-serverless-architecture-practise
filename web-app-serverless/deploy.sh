#!/usr/bin/env bash
set -euo pipefail

# Simple deployment helper for this Terraform stack.
# - Verifies prerequisites
# - Supports remote (S3) or local backend
# - Runs init, plan, apply, and prints outputs
# - Optional: --destroy to tear everything down

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

BUCKET_NAME="learning-bucket-terraform-state"
BUCKET_REGION="eu-west-1"
USE_LOCAL_BACKEND=false
AUTO_APPROVE=false
DO_DESTROY=false
SKIP_BUCKET_CHECK=false

usage() {
  cat <<EOF
Usage: ./deploy.sh [options]

Options:
  --local             Initialize without remote S3 backend (use local state)
  --auto-approve      Skip interactive approval during apply/destroy
  --destroy           Destroy the stack instead of applying
  --skip-bucket-check Skip checking that the remote state bucket exists
  -h, --help          Show this help

Examples:
  ./deploy.sh                      # remote backend (S3) if available
  ./deploy.sh --local              # use local backend for quick tests
  ./deploy.sh --auto-approve       # non-interactive apply
  ./deploy.sh --destroy --auto-approve  # non-interactive destroy
EOF
}

for arg in "$@"; do
  case "$arg" in
    --local) USE_LOCAL_BACKEND=true ;;
    --auto-approve) AUTO_APPROVE=true ;;
    --destroy) DO_DESTROY=true ;;
    --skip-bucket-check) SKIP_BUCKET_CHECK=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $arg" ; usage ; exit 1 ;;
  esac
done

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: '$1' is required but not found in PATH." >&2
    exit 1
  fi
}

echo "[+] Checking prerequisites..."
require_cmd terraform
require_cmd aws

if [[ "$USE_LOCAL_BACKEND" == false && "$SKIP_BUCKET_CHECK" == false ]]; then
  echo "[+] Verifying remote state bucket: $BUCKET_NAME"
  if ! aws s3api head-bucket --bucket "$BUCKET_NAME" >/dev/null 2>&1; then
    echo "\nRemote state bucket not found: $BUCKET_NAME" >&2
    echo "Create it (once) and re-run, or use local state with --local." >&2
    echo "Example:" >&2
    echo "  aws s3api create-bucket --bucket $BUCKET_NAME --region $BUCKET_REGION --create-bucket-configuration LocationConstraint=$BUCKET_REGION" >&2
    exit 1
  fi
fi

if [[ "$DO_DESTROY" == true ]]; then
  echo "[+] Initializing Terraform (backend: $([[ "$USE_LOCAL_BACKEND" == true ]] && echo local || echo remote))"
  if [[ "$USE_LOCAL_BACKEND" == true ]]; then
    terraform init -backend=false
  else
    terraform init
  fi

  echo "[+] Destroying stack..."
  if [[ "$AUTO_APPROVE" == true ]]; then
    terraform destroy -auto-approve
  else
    terraform destroy
  fi
  echo "[✓] Destroy complete."
  exit 0
fi

echo "[+] Initializing Terraform (backend: $([[ "$USE_LOCAL_BACKEND" == true ]] && echo local || echo remote))"
if [[ "$USE_LOCAL_BACKEND" == true ]]; then
  terraform init -backend=false
else
  terraform init
fi

echo "[+] Planning changes..."
terraform plan -out plan.tfplan

if [[ "$AUTO_APPROVE" == true ]]; then
  echo "[+] Applying plan (auto-approve)..."
  terraform apply -auto-approve "plan.tfplan"
else
  echo
  read -r -p "Apply the plan now? [y/N]: " ANSWER
  if [[ "$ANSWER" =~ ^[Yy]$ ]]; then
    terraform apply "plan.tfplan"
  else
    echo "[!] Apply skipped by user. Exiting."
    exit 0
  fi
fi

echo "\n[+] Deployment outputs:"
terraform output || true

cat <<EONOTE

Tips:
- If you don't see a CloudFront domain in outputs, wait a few minutes and check CloudFront in the AWS Console.
- API base URL should be in 'api_gateway_invoke_url'.

EONOTE

echo "[✓] Done."
