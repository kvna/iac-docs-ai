##############################################################################
# Core Variables
##############################################################################

variable "location" {
  description = "Azure region for resource deployment"
  type        = string
  default     = "northeurope"

  validation {
    condition     = can(regex("^[a-z]+[0-9]*$", var.location))
    error_message = "Location must be a valid Azure region name (lowercase, no spaces)."
  }
}

variable "region_code" {
  description = "Short code for the Azure region (for naming)"
  type        = string
  default     = "northeu"
}

variable "cost_center" {
  description = "Cost center for billing and chargeback"
  type        = string
  default     = "IT-Learning"
}

variable "owner" {
  description = "Owner email or team name"
  type        = string
  default     = "iac-team@company.com"
}

##############################################################################
# Azure AI Search Variables
##############################################################################

variable "search_sku" {
  description = "SKU for Azure AI Search service (free, basic, standard, standard2, standard3, storage_optimized_l1, storage_optimized_l2)"
  type        = string
  default     = "basic"

  validation {
    condition     = contains(["free", "basic", "standard"], var.search_sku)
    error_message = "Search SKU must be 'free', 'basic', or 'standard' for POC."
  }
}

variable "enable_semantic_search" {
  description = "Enable semantic search capabilities (requires Basic tier or higher)"
  type        = bool
  default     = true  # Enable for better AI search results with paid tier
}

##############################################################################
# Azure OpenAI Variables
##############################################################################

variable "openai_location" {
  description = "Azure region for OpenAI service (limited availability - swedencentral is closest to North Europe)"
  type        = string
  default     = "swedencentral"  # Closest to North Europe with OpenAI availability

  validation {
    condition = contains([
      "eastus",
      "eastus2",
      "westus",
      "westus2",
      "canadaeast",
      "francecentral",
      "japaneast",
      "australiaeast",
      "swedencentral",
      "switzerlandnorth",
      "uksouth",
      "northeurope"
    ], var.openai_location)
    error_message = "OpenAI location must be a region where Azure OpenAI is available."
  }
}

##############################################################################
# Function App Variables
##############################################################################

variable "function_app_sku" {
  description = "SKU for Function App service plan (Y1 for Consumption, B1 for Basic, S1 for Standard)"
  type        = string
  default     = "Y1"

  validation {
    condition     = contains(["Y1", "B1", "S1"], var.function_app_sku)
    error_message = "Function App SKU must be Y1 (Consumption), B1 (Basic), or S1 (Standard)."
  }
}

##############################################################################
# Feature Flags
##############################################################################

variable "enable_monitoring" {
  description = "Enable Application Insights monitoring"
  type        = bool
  default     = true
}

variable "enable_diagnostic_logs" {
  description = "Enable diagnostic logging to Log Analytics"
  type        = bool
  default     = false  # Disabled by default for POC cost savings
}

variable "enable_static_web_app" {
  description = "Deploy Azure Static Web App for documentation UI"
  type        = bool
  default     = false  # Optional feature
}

variable "static_web_app_location" {
  description = "Azure region for Static Web App (limited regions available)"
  type        = string
  default     = "westeurope"  # Closest to North Europe with Static Web Apps availability

  validation {
    condition = contains([
      "eastus2",
      "westus2",
      "centralus",
      "westeurope",
      "eastasia"
    ], var.static_web_app_location)
    error_message = "Static Web App location must be a region where Static Web Apps is available."
  }
}

##############################################################################
# Network Configuration
##############################################################################

variable "allowed_ip_ranges" {
  description = "List of IP ranges allowed to access resources (empty list = allow all)"
  type        = list(string)
  default     = []  # Allow all for POC; restrict for production

  validation {
    condition = alltrue([
      for ip in var.allowed_ip_ranges : can(regex("^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}(/[0-9]{1,2})?$", ip))
    ])
    error_message = "IP ranges must be valid CIDR notation (e.g., 192.168.1.0/24)."
  }
}

##############################################################################
# Tags
##############################################################################

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
