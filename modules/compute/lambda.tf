# ─── Zip Lambda source code ───────────────────────────────────────────────────
data "archive_file" "greeter" {
  type        = "zip"
  source_file = "${path.module}/lambda/greeter/index.py"
  output_path = "${path.module}/lambda/greeter/greeter.zip"
}

# ─── CloudWatch Log Group ─────────────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "lambda_greeter" {
  name              = "/aws/lambda/${var.project_name}-${var.region}-greeter"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloudwatch.arn
}

# ─── Lambda: Greeter ──────────────────────────────────────────────────────────
resource "aws_lambda_function" "greeter" {
  function_name    = "${var.project_name}-${var.region}-greeter"
  role             = aws_iam_role.lambda_greeter.arn
  runtime          = var.lambda_runtime
  handler          = "index.handler"
  filename         = data.archive_file.greeter.output_path
  source_code_hash = data.archive_file.greeter.output_base64sha256
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_mb
  kms_key_arn      = aws_kms_key.cloudwatch.arn

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.greeting_logs.name
      SNS_TOPIC_ARN       = var.sns_topic_arn
      CANDIDATE_EMAIL     = var.email
      GITHUB_REPO         = var.github_repo
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda_greeter]
}

# ─── Lambda: Dispatcher ───────────────────────────────────────────────────────
data "archive_file" "dispatcher" {
  type        = "zip"
  source_file = "${path.module}/lambda/dispatcher/index.py"
  output_path = "${path.module}/lambda/dispatcher/dispatcher.zip"
}

resource "aws_cloudwatch_log_group" "lambda_dispatcher" {
  name              = "/aws/lambda/${var.project_name}-${var.region}-dispatcher"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloudwatch.arn
}

resource "aws_lambda_function" "dispatcher" {
  function_name    = "${var.project_name}-${var.region}-dispatcher"
  role             = aws_iam_role.lambda_dispatcher.arn
  runtime          = var.lambda_runtime
  handler          = "index.handler"
  filename         = data.archive_file.dispatcher.output_path
  source_code_hash = data.archive_file.dispatcher.output_base64sha256
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_mb
  kms_key_arn      = aws_kms_key.cloudwatch.arn

  environment {
    variables = {
      ECS_CLUSTER_ARN     = aws_ecs_cluster.main.arn
      ECS_TASK_DEFINITION = aws_ecs_task_definition.sns_publisher.arn
      SUBNET_IDS          = join(",", var.subnet_ids)
      SECURITY_GROUP_ID   = var.ecs_security_group_id
      SNS_TOPIC_ARN       = var.sns_topic_arn
      CANDIDATE_EMAIL     = var.email
      GITHUB_REPO         = var.github_repo
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda_dispatcher]
}
