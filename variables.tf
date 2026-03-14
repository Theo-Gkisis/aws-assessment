variable "test_user_password" {
  description = "Permanent password for the Cognito test user. Must meet the User Pool password policy."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.test_user_password) >= 8
    error_message = "Password must be at least 8 characters long."
  }
}

variable "sns_topic_arn" {
  description = "SNS Topic ARN for verification payloads. Defaults to Unleash Live topic."
  type        = string
  default     = "arn:aws:sns:us-east-1:637226132752:Candidate-Verification-Topic"
}

# ── Networking ────────────────────────────────────────────────────────────────

variable "vpc_cidr_us" {
  description = "VPC CIDR block for us-east-1."
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_cidr_eu" {
  description = "VPC CIDR block for eu-west-1."
  type        = string
  default     = "10.1.0.0/16"
}

variable "subnet_count" {
  description = "Number of public subnets per VPC."
  type        = number
  default     = 2
}

# ── DynamoDB ──────────────────────────────────────────────────────────────────

variable "dynamodb_table_name" {
  description = "Name of the regional DynamoDB table."
  type        = string
  default     = "GreetingLogs"
}

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode."
  type        = string
  default     = "PAY_PER_REQUEST"
}

# ── Lambda ────────────────────────────────────────────────────────────────────

variable "lambda_runtime" {
  description = "Lambda runtime."
  type        = string
  default     = "python3.12"
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds."
  type        = number
  default     = 30
}

variable "lambda_memory_mb" {
  description = "Lambda memory in MB."
  type        = number
  default     = 128
}

# ── ECS Fargate ───────────────────────────────────────────────────────────────

variable "ecs_task_cpu" {
  description = "ECS task CPU units."
  type        = number
  default     = 256
}

variable "ecs_task_memory" {
  description = "ECS task memory in MB."
  type        = number
  default     = 512
}

variable "ecs_container_image" {
  description = "Container image for the ECS SNS publisher task."
  type        = string
  default     = "amazon/aws-cli"
}

# ── API Gateway ───────────────────────────────────────────────────────────────

variable "api_stage_name" {
  description = "API Gateway stage name."
  type        = string
  default     = "v1"
}
