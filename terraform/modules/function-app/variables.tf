variable "name" {
  description = "Name of the Function App"
  type        = string
}

variable "plan_name" {
  description = "Name of the App Service Plan"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "os_type" {
  description = "OS type (Linux or Windows)"
  type        = string
  default     = "Linux"
}

variable "sku_name" {
  description = "SKU name (Y1 for Consumption, B1 for Basic, etc.)"
  type        = string
  default     = "Y1"
}

variable "storage_account_name" {
  description = "Storage account name for function app"
  type        = string
}

variable "storage_account_access_key" {
  description = "Storage account access key"
  type        = string
  sensitive   = true
}

variable "app_settings" {
  description = "Application settings"
  type        = map(string)
  default     = {}
}

variable "identity_type" {
  description = "Managed identity type"
  type        = string
  default     = "SystemAssigned"
}

variable "cors_allowed_origins" {
  description = "CORS allowed origins"
  type        = list(string)
  default     = ["*"]
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
