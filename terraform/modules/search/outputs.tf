output "id" {
  description = "Search service ID"
  value       = azurerm_search_service.main.id
}

output "name" {
  description = "Search service name"
  value       = azurerm_search_service.main.name
}

output "endpoint" {
  description = "Search service endpoint URL"
  value       = "https://${azurerm_search_service.main.name}.search.windows.net"
}

output "primary_key" {
  description = "Primary admin key"
  value       = azurerm_search_service.main.primary_key
  sensitive   = true
}

output "query_keys" {
  description = "Query-only API keys"
  value       = azurerm_search_service.main.query_keys
  sensitive   = true
}
