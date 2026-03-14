resource "aws_dynamodb_table" "greeting_logs" {
  name         = "${var.project_name}-${var.dynamodb_table_name}"
  billing_mode = var.dynamodb_billing_mode
  hash_key     = "request_id"
  range_key    = "timestamp"

  attribute {
    name = "request_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  # Auto-delete old records — Lambda sets expires_at (Unix epoch)
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  # Point-in-time recovery — enables restore to any second in the last 35 days
  point_in_time_recovery {
    enabled = true
  }

  # Encryption at rest with Customer Managed Key (CMK)
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb.arn
  }

  tags = { Name = "${var.project_name}-greeting-logs" }
}
