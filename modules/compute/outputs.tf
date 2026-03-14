output "api_url" {
  description = "Base URL of the HTTP API Gateway"
  value       = aws_apigatewayv2_stage.main.invoke_url
}

output "greeter_function_name" {
  description = "Greeter Lambda function name"
  value       = aws_lambda_function.greeter.function_name
}
