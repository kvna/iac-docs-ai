terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
  }
}

##############################################################################
# App Service Plan
##############################################################################

resource "azurerm_service_plan" "main" {
  name                = var.plan_name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = var.os_type
  sku_name            = var.sku_name

  tags = var.tags
}

##############################################################################
# Function App
##############################################################################

resource "azurerm_linux_function_app" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  service_plan_id            = azurerm_service_plan.main.id
  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key

  site_config {
    application_stack {
      python_version = "3.11"
    }

    # CORS for web access
    cors {
      allowed_origins = var.cors_allowed_origins
    }
  }

  app_settings = var.app_settings

  identity {
    type = var.identity_type
  }

  https_only = true

  tags = var.tags
}
