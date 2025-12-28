output "id" {
  description = "Function App ID"
  value       = azurerm_linux_function_app.main.id
}

output "name" {
  description = "Function App name"
  value       = azurerm_linux_function_app.main.name
}

output "default_hostname" {
  description = "Default hostname"
  value       = azurerm_linux_function_app.main.default_hostname
}

output "principal_id" {
  description = "Managed identity principal ID"
  value       = azurerm_linux_function_app.main.identity[0].principal_id
}

output "outbound_ip_addresses" {
  description = "Outbound IP addresses"
  value       = azurerm_linux_function_app.main.outbound_ip_addresses
}
