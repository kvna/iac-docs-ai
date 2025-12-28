output "id" {
  description = "OpenAI service ID"
  value       = azurerm_cognitive_account.openai.id
}

output "name" {
  description = "OpenAI service name"
  value       = azurerm_cognitive_account.openai.name
}

output "endpoint" {
  description = "OpenAI service endpoint"
  value       = azurerm_cognitive_account.openai.endpoint
}

output "primary_key" {
  description = "Primary API key"
  value       = azurerm_cognitive_account.openai.primary_access_key
  sensitive   = true
}

output "secondary_key" {
  description = "Secondary API key"
  value       = azurerm_cognitive_account.openai.secondary_access_key
  sensitive   = true
}

output "model_deployments" {
  description = "Deployed models"
  value = {
    for k, v in azurerm_cognitive_deployment.models : k => {
      id   = v.id
      name = v.name
    }
  }
}
