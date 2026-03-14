# ─── Trust policy helpers ─────────────────────────────────────────────────────
data "aws_iam_policy_document" "lambda_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ─── Lambda Greeter Role ──────────────────────────────────────────────────────
resource "aws_iam_role" "lambda_greeter" {
  name               = "${var.project_name}-${var.region}-lambda-greeter"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json

  tags = { Name = "${var.project_name}-lambda-greeter" }
}

# ─── Lambda Dispatcher Role ───────────────────────────────────────────────────
resource "aws_iam_role" "lambda_dispatcher" {
  name               = "${var.project_name}-${var.region}-lambda-dispatcher"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json

  tags = { Name = "${var.project_name}-lambda-dispatcher" }
}

# ─── ECS Task Execution Role (pulls image + writes logs) ─────────────────────
resource "aws_iam_role" "ecs_execution" {
  name               = "${var.project_name}-${var.region}-ecs-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_trust.json

  tags = { Name = "${var.project_name}-ecs-execution" }
}

# ─── ECS Task Role (runtime permissions of the container) ────────────────────
resource "aws_iam_role" "ecs_task" {
  name               = "${var.project_name}-${var.region}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_trust.json

  tags = { Name = "${var.project_name}-ecs-task" }
}
