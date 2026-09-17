data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "aws_default_ebs_encryption_by_default" "this" {
  enabled = true
}

resource "aws_flow_log" "vpc" {
  vpc_id               = var.vpc_id
  traffic_type         = "ALL"
  iam_role_arn         = aws_iam_role.vpc_flow_logs.arn
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/${var.environment}/flow-logs"
  retention_in_days = 90
}

resource "aws_s3_bucket" "audit" {
  bucket        = "${var.environment}-${data.aws_caller_identity.current.account_id}-audit"
  force_destroy = false
}

resource "aws_s3_bucket_public_access_block" "audit" {
  bucket                  = aws_s3_bucket.audit.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "audit" {
  bucket = aws_s3_bucket.audit.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit" {
  bucket = aws_s3_bucket.audit.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}