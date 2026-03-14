# ─── ECS Cluster ──────────────────────────────────────────────────────────────
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.region}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = { Name = "${var.project_name}-${var.region}-cluster" }
}

# ─── CloudWatch Log Group ─────────────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "ecs_sns_publisher" {
  name              = "/ecs/${var.project_name}-${var.region}-sns-publisher"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloudwatch.arn
}

# ─── Task Definition: SNS Publisher ──────────────────────────────────────────
resource "aws_ecs_task_definition" "sns_publisher" {
  family                   = "${var.project_name}-${var.region}-sns-publisher"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "sns-publisher"
      image = var.ecs_container_image

      # Publishes the required verification payload to SNS
      # Env vars (SNS_TOPIC_ARN, CANDIDATE_EMAIL, GITHUB_REPO) are injected
      # at runtime by the dispatcher Lambda via containerOverrides
      # Override entrypoint so we can use shell variable expansion
      entryPoint = ["sh", "-c"]
      command = [
        "aws sns publish --topic-arn \"$SNS_TOPIC_ARN\" --message \"{\\\"email\\\":\\\"$CANDIDATE_EMAIL\\\",\\\"source\\\":\\\"ECS\\\",\\\"region\\\":\\\"$REGION\\\",\\\"repo\\\":\\\"$GITHUB_REPO\\\"}\" --region us-east-1"
      ]

      environment = [
        { name = "REGION", value = var.region }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_sns_publisher.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}
