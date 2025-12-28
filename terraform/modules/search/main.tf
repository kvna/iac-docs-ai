terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
  }
}

##############################################################################
# Azure AI Search Service
##############################################################################

resource "azurerm_search_service" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku

  partition_count = var.partition_count
  replica_count   = var.replica_count

  # Public network access
  public_network_access_enabled = var.public_network_access_enabled

  # Semantic search (AI-powered)
  semantic_search_sku = var.semantic_search_sku

  # Authentication
  local_authentication_enabled = true  # For API key access

  tags = var.tags
}
