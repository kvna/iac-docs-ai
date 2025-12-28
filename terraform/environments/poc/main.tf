terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
  }

  # Backend configuration for state storage
  # Uncomment and configure after initial deployment
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state-prod-eastus2"
  #   storage_account_name = "sttfstateprodeastus2001"
  #   container_name       = "tfstate"
  #   key                  = "iac-docs-poc.tfstate"
  # }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azuread" {}

# Get current client configuration
data "azurerm_client_config" "current" {}

# Local variables for resource naming and common tags
locals {
  # Naming convention
  workload    = "iac-docs"
  environment = "poc"
  location    = var.location
  region_code = var.region_code

  # Resource name components
  resource_suffix = "${local.workload}-${local.environment}-${local.region_code}"

  # Common tags applied to all resources
  common_tags = {
    Environment  = local.environment
    Workload     = "IaC Documentation Search"
    ManagedBy    = "terraform"
    CostCenter   = var.cost_center
    Owner        = var.owner
    Purpose      = "AI-powered documentation search POC"
    AutoShutdown = "true"  # Marker for cost optimization scripts
  }

  # Resource names
  rg_name              = "rg-${local.resource_suffix}"
  storage_name         = lower(replace("st${local.workload}${local.environment}${local.region_code}001", "/[^a-z0-9]/", ""))
  search_name          = "search-${local.resource_suffix}"
  openai_name          = "openai-${local.resource_suffix}"
  func_plan_name       = "plan-${local.resource_suffix}"
  func_app_name        = "func-${local.resource_suffix}"
  app_insights_name    = "appi-${local.resource_suffix}"
  log_analytics_name   = "log-${local.resource_suffix}"
  key_vault_name       = "kv-${local.workload}-${local.environment}-${local.region_code}"  # Max 24 chars
}

##############################################################################
# Resource Group
##############################################################################

resource "azurerm_resource_group" "main" {
  name     = local.rg_name
  location = local.location
  tags     = local.common_tags
}

##############################################################################
# Storage Account
# Purpose: Document storage, function app storage, terraform state (optional)
##############################################################################

module "storage" {
  source = "../../modules/storage"

  name                = local.storage_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  # Storage configuration
  account_tier              = "Standard"
  account_replication_type  = "LRS"  # Locally redundant for POC cost savings
  enable_https_traffic_only = true
  min_tls_version          = "TLS1_2"

  # Network rules - adjust based on security requirements
  network_rules = {
    default_action = "Allow"  # Change to "Deny" for production
    ip_rules       = []
    bypass         = ["AzureServices"]
  }

  # Containers for different purposes
  containers = [
    {
      name        = "documents"
      access_type = "private"
    },
    {
      name        = "test-results"
      access_type = "private"
    },
    {
      name        = "tfstate"
      access_type = "private"
    }
  ]

  tags = local.common_tags
}

##############################################################################
# Log Analytics Workspace
# Purpose: Centralized logging and monitoring
##############################################################################

resource "azurerm_log_analytics_workspace" "main" {
  name                = local.log_analytics_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "PerGB2018"
  retention_in_days   = 30  # Minimum for POC cost savings

  tags = local.common_tags
}

##############################################################################
# Application Insights
# Purpose: Application monitoring and diagnostics
##############################################################################

resource "azurerm_application_insights" "main" {
  name                = local.app_insights_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"

  tags = local.common_tags
}

##############################################################################
# Azure Cognitive Search (AI Search)
# Purpose: Document indexing and search capabilities
##############################################################################

module "search" {
  source = "../../modules/search"

  name                = local.search_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  # SKU configuration
  # Free: 50MB, 3 indexes, no SLA (good for POC)
  # Basic: 2GB, 15 indexes, SLA (better for realistic testing)
  sku = var.search_sku

  # Search configuration
  partition_count = 1
  replica_count   = 1

  # Enable semantic search for better AI-powered results
  # Semantic search requires Basic tier or higher (not available with free tier)
  semantic_search_sku = var.enable_semantic_search && var.search_sku != "free" ? "free" : null

  tags = local.common_tags
}

##############################################################################
# Azure OpenAI
# Purpose: Generate embeddings and enhance search queries
##############################################################################

module "openai" {
  source = "../../modules/openai"

  name                = local.openai_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.openai_location  # OpenAI has limited region availability

  # SKU configuration
  sku_name = "S0"  # Standard tier

  # Model deployments
  model_deployments = [
    {
      name          = "text-embedding-ada-002"
      model_name    = "text-embedding-ada-002"
      model_version = "2"
      scale_type    = "Standard"
      capacity      = 50
    },
    {
      name          = "gpt-4o-mini"
      model_name    = "gpt-4o-mini"
      model_version = "2024-07-18"
      scale_type    = "Standard"
      capacity      = 50
    }
  ]

  # Network access
  public_network_access_enabled = true  # For POC; restrict for production

  tags = local.common_tags
}

##############################################################################
# Key Vault
# Purpose: Secure storage for API keys and secrets
##############################################################################

resource "azurerm_key_vault" "main" {
  name                = substr(local.key_vault_name, 0, 24)
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"

  # Soft delete and purge protection
  soft_delete_retention_days = 7
  purge_protection_enabled   = false  # Disabled for POC to allow easy cleanup

  # Network ACLs
  network_acls {
    default_action = "Allow"  # Change to "Deny" for production
    bypass         = "AzureServices"
  }

  # Access policy for current user/service principal
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Purge"
    ]

    key_permissions = [
      "Get",
      "List",
      "Create",
      "Delete",
      "Purge"
    ]
  }

  tags = local.common_tags
}

# Store Azure Search API Key in Key Vault
resource "azurerm_key_vault_secret" "search_admin_key" {
  name         = "search-admin-key"
  value        = module.search.primary_key
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_key_vault.main
  ]
}

# Store Azure OpenAI API Key in Key Vault
resource "azurerm_key_vault_secret" "openai_key" {
  name         = "openai-api-key"
  value        = module.openai.primary_key
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_key_vault.main
  ]
}

# Store Application Insights Instrumentation Key
resource "azurerm_key_vault_secret" "app_insights_key" {
  name         = "app-insights-instrumentation-key"
  value        = azurerm_application_insights.main.instrumentation_key
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_key_vault.main
  ]
}

##############################################################################
# Function App and App Service Plan
# Purpose: API endpoints for search functionality
# NOTE: Temporarily disabled due to quota limitations in North Europe
##############################################################################

# module "function_app" {
#   source = "../../modules/function-app"
#
#   name                = local.func_app_name
#   resource_group_name = azurerm_resource_group.main.name
#   location            = azurerm_resource_group.main.location
#
#   # App Service Plan configuration
#   # Consumption: Pay per execution, auto-scale, free tier available
#   # Basic/Standard: Always-on, more predictable performance
#   plan_name = local.func_plan_name
#   os_type   = "Linux"
#   sku_name  = var.function_app_sku  # "Y1" for Consumption, "B1" for Basic
#
#   # Storage account for function app
#   storage_account_name       = module.storage.name
#   storage_account_access_key = module.storage.primary_access_key
#
#   # Application settings
#   app_settings = {
#     "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.main.instrumentation_key
#     "FUNCTIONS_WORKER_RUNTIME"       = "python"
#     "PYTHON_VERSION"                 = "3.11"
#
#     # Azure Search configuration
#     "SEARCH_SERVICE_NAME"     = module.search.name
#     "SEARCH_ADMIN_KEY"        = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.search_admin_key.id})"
#     "SEARCH_API_VERSION"      = "2023-11-01"
#     "SEARCH_INDEX_NAME"       = "iac-documentation"
#
#     # Azure OpenAI configuration
#     "OPENAI_ENDPOINT"         = module.openai.endpoint
#     "OPENAI_API_KEY"          = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.openai_key.id})"
#     "OPENAI_API_VERSION"      = "2024-02-01"
#     "OPENAI_EMBEDDING_MODEL"  = "text-embedding-ada-002"
#     "OPENAI_CHAT_MODEL"       = "gpt-4o-mini"
#
#     # Storage configuration
#     "STORAGE_ACCOUNT_NAME"    = module.storage.name
#     "STORAGE_CONTAINER_NAME"  = "documents"
#   }
#
#   # Identity for Key Vault access
#   identity_type = "SystemAssigned"
#
#   tags = local.common_tags
#
#   depends_on = [
#     azurerm_key_vault.main,
#     module.storage
#   ]
# }
#
# # Grant Function App access to Key Vault
# resource "azurerm_key_vault_access_policy" "function_app" {
#   key_vault_id = azurerm_key_vault.main.id
#   tenant_id    = data.azurerm_client_config.current.tenant_id
#   object_id    = module.function_app.principal_id
#
#   secret_permissions = [
#     "Get",
#     "List"
#   ]
#
#   depends_on = [
#     module.function_app
#   ]
# }

##############################################################################
# Static Web App (Optional - for simple UI)
# Uncomment if you want a hosted web interface
##############################################################################

# resource "azurerm_static_site" "main" {
#   name                = "static-${local.resource_suffix}"
#   resource_group_name = azurerm_resource_group.main.name
#   location            = "East US 2"  # Static Web Apps has limited regions
#   sku_tier            = "Free"
#   sku_size            = "Free"
#
#   tags = local.common_tags
# }

##############################################################################
# Outputs
##############################################################################

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = module.storage.name
}

output "storage_connection_string" {
  description = "Connection string for storage account"
  value       = module.storage.primary_connection_string
  sensitive   = true
}

output "search_service_name" {
  description = "Name of the Azure AI Search service"
  value       = module.search.name
}

output "search_endpoint" {
  description = "Endpoint URL for Azure AI Search"
  value       = module.search.endpoint
}

output "openai_endpoint" {
  description = "Endpoint URL for Azure OpenAI"
  value       = module.openai.endpoint
}

# Function App outputs - disabled due to quota limitations
# output "function_app_name" {
#   description = "Name of the Function App"
#   value       = module.function_app.name
# }
#
# output "function_app_default_hostname" {
#   description = "Default hostname of the Function App"
#   value       = module.function_app.default_hostname
# }

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "deployment_summary" {
  description = "Summary of deployed resources for quick reference"
  value = {
    resource_group        = azurerm_resource_group.main.name
    location             = azurerm_resource_group.main.location
    search_service       = module.search.name
    search_sku           = var.search_sku
    openai_service       = module.openai.name
    # function_app         = module.function_app.name  # Disabled due to quota
    storage_account      = module.storage.name
    key_vault            = azurerm_key_vault.main.name
    cost_center          = var.cost_center
    web_app_url          = try(azurerm_static_web_app.docs_ui.default_host_name, null)
    function_app_url     = try(azurerm_linux_function_app.docs_api.default_hostname, null)
  }
}

##############################################################################
# Web Resources Outputs
##############################################################################

output "static_web_app_url" {
  description = "URL of the Static Web App"
  value       = azurerm_static_web_app.docs_ui.default_host_name
}

output "static_web_app_api_key" {
  description = "API key for deploying to Static Web App"
  value       = azurerm_static_web_app.docs_ui.api_key
  sensitive   = true
}

output "function_app_url" {
  description = "URL of the Function App API"
  value       = azurerm_linux_function_app.docs_api.default_hostname
}

output "function_app_name" {
  description = "Name of the Function App"
  value       = azurerm_linux_function_app.docs_api.name
}
