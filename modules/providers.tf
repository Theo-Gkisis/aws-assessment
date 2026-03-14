terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ─── Primary region: Authentication + Compute ────────────────────────────────
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# ─── Secondary region: Compute only ──────────────────────────────────────────
provider "aws" {
  alias  = "eu_west_1"
  region = "eu-west-1"
}
