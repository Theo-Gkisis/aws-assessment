data "aws_caller_identity" "current" {}

# ─── KMS Key: CloudWatch Logs + Lambda env vars ───────────────────────────────
resource "aws_kms_key" "cloudwatch" {
  description             = "KMS CMK for CloudWatch Log Groups and Lambda env vars"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableIAMUserPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = { Name = "${var.project_name}-${var.region}-cloudwatch-key" }
}

resource "aws_kms_alias" "cloudwatch" {
  name          = "alias/${var.project_name}-${var.region}-cloudwatch-v1"
  target_key_id = aws_kms_key.cloudwatch.key_id
}

# ─── KMS Key: DynamoDB ────────────────────────────────────────────────────────
resource "aws_kms_key" "dynamodb" {
  description             = "KMS CMK for DynamoDB table encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableIAMUserPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowDynamoDB"
        Effect = "Allow"
        Principal = {
          Service = "dynamodb.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = { Name = "${var.project_name}-${var.region}-dynamodb-key" }
}

resource "aws_kms_alias" "dynamodb" {
  name          = "alias/${var.project_name}-${var.region}-dynamodb-v1"
  target_key_id = aws_kms_key.dynamodb.key_id
}
