# Static Web App for frontend hosting
resource "azurerm_static_web_app" "docs_ui" {
  name                = "stapp-${local.resource_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.static_web_app_location
  sku_tier            = "Free"
  sku_size            = "Free"

  tags = local.common_tags
}

# Function App for API backend
resource "azurerm_service_plan" "functions" {
  name                = "asp-${local.resource_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = "westeurope"  # Using West Europe due to quota limits in North Europe
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption plan

  tags = local.common_tags
}

resource "azurerm_linux_function_app" "docs_api" {
  name                = "func-${local.resource_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = "westeurope"  # Match service plan location

  storage_account_name       = azurerm_storage_account.functions.name
  storage_account_access_key = azurerm_storage_account.functions.primary_access_key
  service_plan_id            = azurerm_service_plan.functions.id

  site_config {
    application_stack {
      python_version = "3.11"
    }

    cors {
      allowed_origins = [
        "https://${azurerm_static_web_app.docs_ui.default_host_name}",
        "http://localhost:3000",
        "http://localhost:5500",
        "http://127.0.0.1:5500"
      ]
      support_credentials = false
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"       = "python"
    "SEARCH_ENDPOINT"                = module.search.endpoint
    "SEARCH_KEY"                     = module.search.primary_key
    "SEARCH_INDEX"                   = "docs-index"
    "OPENAI_ENDPOINT"                = module.openai.endpoint
    "OPENAI_KEY"                     = module.openai.primary_key
    "OPENAI_DEPLOYMENT"              = "gpt-4"
    "EMBEDDING_DEPLOYMENT"           = "text-embedding-ada-002"
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.main.instrumentation_key
  }

  tags = local.common_tags
}

# Storage account for Function App
resource "azurerm_storage_account" "functions" {
  name                     = "stfnciacdocspocn002"  # Limited to 24 chars: st+fnc+iacdocs+poc+n+002
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  tags = local.common_tags
}
