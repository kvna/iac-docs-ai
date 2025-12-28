terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
  }
}

##############################################################################
# Storage Account
##############################################################################

resource "azurerm_storage_account" "main" {
  name                      = var.name
  resource_group_name       = var.resource_group_name
  location                  = var.location
  account_tier              = var.account_tier
  account_replication_type  = var.account_replication_type
  enable_https_traffic_only = var.enable_https_traffic_only
  min_tls_version          = var.min_tls_version
  allow_nested_items_to_be_public = false  # Security best practice

  tags = var.tags
}

##############################################################################
# Blob Containers
##############################################################################

resource "azurerm_storage_container" "containers" {
  for_each = { for c in var.containers : c.name => c }

  name                  = each.value.name
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = each.value.access_type
}

##############################################################################
# Network Rules
##############################################################################

resource "azurerm_storage_account_network_rules" "main" {
  count = var.network_rules != null ? 1 : 0

  storage_account_id = azurerm_storage_account.main.id

  default_action             = var.network_rules.default_action
  ip_rules                   = var.network_rules.ip_rules
  virtual_network_subnet_ids = []
  bypass                     = var.network_rules.bypass
}
