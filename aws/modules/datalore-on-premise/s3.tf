resource "random_string" "s3_prefix" {
  length           = 16
  special          = true
  override_special = "-"
  upper            = false
  lifecycle {
    ignore_changes = [override_special]
  }
}

resource "aws_s3_bucket" "blob-storage" {
  bucket        = "${var.name_prefix}-${random_string.s3_prefix.result}-blob-storage"
  force_destroy = true

  versioning {
    enabled = false
  }

  tags = {
    CreatedBy = "Terraform",
  }
}
resource "aws_s3_bucket" "envs" {
  bucket        = "${var.name_prefix}-${random_string.s3_prefix.result}-envs"
  force_destroy = true

  versioning {
    enabled = false
  }

  tags = {
    CreatedBy = "Terraform",
  }
}
resource "aws_s3_bucket" "publishing" {
  bucket        = "${var.name_prefix}-${random_string.s3_prefix.result}-publishing"
  force_destroy = true

  versioning {
    enabled = false
  }

  tags = {
    CreatedBy = "Terraform",
  }
}

resource "aws_s3_bucket_public_access_block" "blob-storage" {
  bucket = aws_s3_bucket.blob-storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_public_access_block" "envs" {
  bucket = aws_s3_bucket.envs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_public_access_block" "publishing" {
  bucket = aws_s3_bucket.publishing.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
