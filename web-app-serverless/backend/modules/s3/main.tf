/** 
 * ----------------------------
 * S3 BUCKET + PRIVATE VPC ENDPOINT
 * ----------------------------
 * Creates an S3 bucket and restricts all public access.
 * Also creates a private S3 VPC endpoint for secure access.
 */
resource "aws_s3_bucket" "this" {
  bucket = "${var.project_name}-data-bucket"
  tags   = merge(var.tags, { Name = "${var.project_name}-bucket" })
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}