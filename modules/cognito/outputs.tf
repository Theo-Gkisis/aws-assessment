output "user_pool_id" {
  description = "Cognito User Pool ID — used by API Gateway JWT Authorizer"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = aws_cognito_user_pool.main.arn
}

output "client_id" {
  description = "Cognito App Client ID — used by the test script to authenticate"
  value       = aws_cognito_user_pool_client.main.id
}

output "endpoint" {
  description = "Cognito JWT issuer URL — used by API Gateway JWT Authorizer"
  value       = "https://${aws_cognito_user_pool.main.endpoint}"
}