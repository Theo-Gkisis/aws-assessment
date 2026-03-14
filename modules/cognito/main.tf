# User Pool
resource "aws_cognito_user_pool" "main" {
  name = "${var.project_name}-user-pool"

  # Use email as the login identifier
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  # Password policy — meets Cognito defaults + assessment requirements
  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  # Allow users to recover account via email
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # Security: block enumeration attacks
  user_pool_add_ons {
    advanced_security_mode = "ENFORCED"
  }
}

# ─── User Pool Client ──────────────────────────────────────────────────────────
resource "aws_cognito_user_pool_client" "main" {
  name         = "${var.project_name}-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # USER_PASSWORD_AUTH needed for the test script (programmatic login)
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]

  # Security: no client secret for public clients; block user-not-found errors
  prevent_user_existence_errors = "ENABLED"

  # Token validity
  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }
  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 30
}

# ─── Test User (permanent password, no FORCE_CHANGE_PASSWORD state) ───────────
resource "aws_cognito_user" "test_user" {
  user_pool_id = aws_cognito_user_pool.main.id
  username     = var.email
  password     = var.test_user_password

  attributes = {
    email          = var.email
    email_verified = "true"
  }

  # Suppress the welcome email — this is a sandbox test user
  message_action = "SUPPRESS"
}