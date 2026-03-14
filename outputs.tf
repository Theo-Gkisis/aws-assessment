output "api_url_us" {
  description = "API Gateway URL - us-east-1"
  value       = module.compute_us.api_url
}

output "api_url_eu" {
  description = "API Gateway URL - eu-west-1"
  value       = module.compute_eu.api_url
}

output "greet_endpoint_us" {
  description = "POST endpoint for greeter - us-east-1"
  value       = "${module.compute_us.api_url}/greet"
}

output "greet_endpoint_eu" {
  description = "POST endpoint for greeter - eu-west-1"
  value       = "${module.compute_eu.api_url}/greet"
}

output "cognito_client_id" {
  description = "Cognito App Client ID"
  value       = module.cognito.client_id
}
