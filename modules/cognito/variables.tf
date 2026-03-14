variable "project_name" {
  description = "Project name used as prefix for all Cognito resources"
  type        = string
}

variable "email" {
  description = "Email address used as the Cognito test user username"
  type        = string
}

variable "test_user_password" {
  description = "Permanent password for the Cognito test user"
  type        = string
  sensitive   = true
}
