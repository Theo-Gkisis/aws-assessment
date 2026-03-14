# ─── General ──────────────────────────────────────────────────────────────────
variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
}

variable "region" {
  description = "AWS region where this compute stack is deployed"
  type        = string
}

# ─── Networking (from networking module outputs) ───────────────────────────────
variable "subnet_ids" {
  description = "List of public subnet IDs for ECS Fargate tasks"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID for ECS Fargate tasks"
  type        = string
}

# ─── Cognito (from cognito module outputs) ────────────────────────────────────
variable "cognito_user_pool_id" {
  description = "Cognito User Pool ID - used by the API Gateway JWT Authorizer"
  type        = string
}

variable "cognito_client_id" {
  description = "Cognito App Client ID - used by the API Gateway JWT Authorizer"
  type        = string
}

variable "cognito_endpoint" {
  description = "Cognito JWT issuer URL - used by the API Gateway JWT Authorizer"
  type        = string
}

# ─── SNS Verification ─────────────────────────────────────────────────────────
variable "sns_topic_arn" {
  description = "Unleash live SNS Topic ARN for candidate verification"
  type        = string
  default     = "arn:aws:sns:us-east-1:637226132752:Candidate-Verification-Topic"
}

variable "email" {
  description = "Candidate email included in the SNS verification payload"
  type        = string
}

variable "github_repo" {
  description = "GitHub repo URL included in the SNS verification payload"
  type        = string
}

# ─── DynamoDB ─────────────────────────────────────────────────────────────────
variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for greeting logs"
  type        = string
  default     = "GreetingLogs"
}

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode - PAY_PER_REQUEST for cost-conscious sandbox"
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.dynamodb_billing_mode)
    error_message = "billing_mode must be PAY_PER_REQUEST or PROVISIONED."
  }
}

# ─── Lambda ───────────────────────────────────────────────────────────────────
variable "lambda_runtime" {
  description = "Lambda runtime version"
  type        = string
  default     = "python3.12"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
}

variable "lambda_memory_mb" {
  description = "Lambda function memory allocation in MB"
  type        = number
  default     = 128
}

# ─── ECS Fargate ──────────────────────────────────────────────────────────────
variable "ecs_task_cpu" {
  description = "ECS task CPU units (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "ecs_task_memory" {
  description = "ECS task memory in MB"
  type        = number
  default     = 512
}

variable "ecs_container_image" {
  description = "Container image for the ECS SNS publisher task"
  type        = string
  default     = "amazon/aws-cli"
}

# ─── API Gateway ──────────────────────────────────────────────────────────────
variable "api_stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "v1"
}
