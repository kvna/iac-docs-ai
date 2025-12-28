terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
  }
}

##############################################################################
# Azure OpenAI Service
##############################################################################

resource "azurerm_cognitive_account" "openai" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  kind                = "OpenAI"
  sku_name            = var.sku_name

  public_network_access_enabled = var.public_network_access_enabled
  custom_subdomain_name         = var.name  # Required for OpenAI

  tags = var.tags
}

##############################################################################
# Model Deployments
##############################################################################

resource "azurerm_cognitive_deployment" "models" {
  for_each = { for m in var.model_deployments : m.name => m }

  name                 = each.value.name
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = each.value.model_name
    version = each.value.model_version
  }

  scale {
    type     = each.value.scale_type
    capacity = each.value.capacity
  }
}
