variable "project_name" {
  description = "Project name used as prefix for all networking resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_count" {
  description = "Number of public subnets to create across availability zones"
  type        = number
  default     = 2
}
