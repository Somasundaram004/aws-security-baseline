resource "aws_guardduty_detector" "this" {
  count  = var.enable_guardduty ? 1 : 0
  enable = true
}

resource "aws_securityhub_account" "this" {
  count                = var.enable_security_hub ? 1 : 0
  enable_default_standards = true
  auto_enable_controls = true
  depends_on           = [aws_guardduty_detector.this]
}

resource "aws_config_configuration_recorder" "this" {
  count    = var.enable_config ? 1 : 0
  name     = "${var.environment}-recorder"
  role_arn = aws_iam_role.config[0].arn
  recording_group { all_supported = true include_global_resource_types = true }
}

resource "aws_iam_role" "config" {
  count = var.enable_config ? 1 : 0
  name  = "${var.environment}-config"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "config.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"]
}

resource "aws_config_delivery_channel" "this" {
  count          = var.enable_config ? 1 : 0
  name           = "${var.environment}-channel"
  s3_bucket_name = aws_s3_bucket.audit.id
  depends_on     = [aws_config_configuration_recorder.this]
}

resource "aws_config_configuration_recorder_status" "this" {
  count      = var.enable_config ? 1 : 0
  name       = aws_config_configuration_recorder.this[0].name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.this]
}