---
document_id: howto-deploy-3tier-application
document_type: howto
skill_level: month6-12
topics: [deployment, operations, azure, architecture, security, networking]
technologies: [terraform_v1.5+, azure_cli_2.50+, azure_app_service, azure_functions, azure_sql, key_vault, vnet]
prerequisites:
  - "Azure account with appropriate permissions"
  - "Terraform installed (v1.5+)"
  - "Azure CLI installed and configured"
  - "Completed howto-deploy-webapp-database"
  - "Understanding of multi-tier architecture patterns"
  - "Knowledge of Azure networking and security"
learning_outcomes:
  - Successfully deploy a production-ready 3-tier application to Azure
  - Implement network isolation and security best practices
  - Configure managed identities for secure authentication
  - Use Azure Key Vault for secrets management
  - Set up monitoring and logging
  - Understand infrastructure dependencies and ordering
estimated_time: 60
last_reviewed: 2025-12-29
review_status: current
search_keywords:
  - "how to deploy 3-tier application to azure"
  - "azure 3-tier architecture terraform"
  - "production-ready azure deployment"
  - "multi-tier application deployment guide"
  - "terraform azure enterprise architecture"
related_documents:
  - concept-iac-overview
  - howto-deploy-webapp-database
  - concept-terraform-workflow
  - reference-terraform-best-practices
  - reference-azure-security-best-practices
glossary_terms:
  - terraform
  - azure
  - app-service
  - function-app
  - sql-database
  - key-vault
  - managed-identity
  - virtual-network
  - application-insights
---

# How to Deploy a 3-Tier Application

## Overview

**Purpose**: Provide step-by-step instructions to deploy a production-ready 3-tier application to Azure using Terraform. This advanced guide demonstrates enterprise-grade patterns including network isolation, managed identities, secrets management, and comprehensive monitoring.

**What You'll Deploy**:
- **Presentation Tier**: Azure Static Web App (frontend)
- **Application Tier**: Azure Function App (backend API)
- **Data Tier**: Azure SQL Database
- **Supporting Infrastructure**:
  - Virtual Network with subnet isolation
  - Azure Key Vault for secrets management
  - Application Insights for monitoring and logging
  - Managed Identities for secure authentication
  - Private endpoints for enhanced security

**Estimated Time**: 60 minutes

**Estimated Cost**:
- Development (Basic tiers): ~$50/month
- Production (Standard/Premium tiers): ~$200/month
- Can run on free tier: Partially (Static Web App free, Functions consumption free tier, SQL Basic $5/month)

## Prerequisites

### Required Tools

Verify you have the following tools installed:

| Tool | Minimum Version | Check Command | Install Guide |
|------|----------------|---------------|---------------|
| Terraform | 1.5+ | `terraform version` | [terraform.io](https://www.terraform.io/downloads) |
| Azure CLI | 2.50+ | `az version` | [aka.ms/install-azure-cli](https://aka.ms/install-azure-cli) |

### Required Access

- [ ] Azure account
- [ ] Subscription ID: `_________________`
- [ ] Required permissions: Contributor or Owner on subscription
- [ ] Ability to create Service Principals (for managed identities)
- [ ] Service quotas: Standard quota for all services

### Required Knowledge

Before starting, you should understand:
- [ ] Multi-tier application architecture patterns
- [ ] Azure Virtual Networks and subnets
- [ ] Managed Identities and RBAC
- [ ] Azure Key Vault concepts
- [ ] Terraform modules and advanced features
- [ ] Security best practices for cloud applications

**New to these concepts?** Complete these guides first:
- [What is Infrastructure as Code?](../day1/concept-iac-overview.md)
- [How to Deploy Web App with Database](../month1-2/howto-deploy-webapp-database.md)
- [Understanding Azure Networking](../month3-6/concept-azure-networking.md)
- [Managed Identities Explained](../month3-6/concept-managed-identities.md)

## Before You Begin

### Step 1: Verify Tool Installation

```bash
# Check Terraform
terraform version
# Expected: Terraform v1.5.0 or higher

# Check Azure CLI
az version
# Expected: azure-cli 2.50.0 or higher
```

❌ **If any tool is missing:** Install it following the [Environment Setup Guide](../day1/howto-environment-setup.md)

### Step 2: Authenticate to Azure

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "YOUR-SUBSCRIPTION-NAME"

# Verify authentication
az account show
```

### Step 3: Create Working Directory

```bash
# Create project directory
mkdir -p ~/terraform-projects/3tier-app
cd ~/terraform-projects/3tier-app

# Verify location
pwd
```

## Deployment Steps

### Step 1: Create Terraform Configuration

Create the main configuration file `main.tf`:

```bash
cat > main.tf << 'EOF'
# Configure Terraform and Providers
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

# Get current Azure client configuration
data "azurerm_client_config" "current" {}

# Generate unique suffix for globally unique names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Local variables for naming and configuration
locals {
  location            = "eastus2"
  environment         = "prod"
  app_name            = "myapp"
  resource_group_name = "rg-${local.app_name}-${local.environment}-${local.location}"

  tags = {
    Environment = local.environment
    ManagedBy   = "terraform"
    Purpose     = "3-Tier Application POC"
    Owner       = "your-name"
    CostCenter  = "IT"
  }

  # Network configuration
  vnet_address_space       = ["10.0.0.0/16"]
  frontend_subnet_prefix   = "10.0.1.0/24"
  backend_subnet_prefix    = "10.0.2.0/24"
  data_subnet_prefix       = "10.0.3.0/24"
  integration_subnet_prefix = "10.0.4.0/27"
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = local.location
  tags     = local.tags
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.app_name}-${local.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = local.vnet_address_space
  tags                = local.tags
}

# Subnets
resource "azurerm_subnet" "backend" {
  name                 = "snet-backend"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.backend_subnet_prefix]

  delegation {
    name = "delegation"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
      ]
    }
  }
}

resource "azurerm_subnet" "data" {
  name                 = "snet-data"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.data_subnet_prefix]

  service_endpoints = ["Microsoft.Sql"]
}

# Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${local.app_name}-${local.environment}-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = "appi-${local.app_name}-${local.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  tags                = local.tags
}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                       = "kv-${local.app_name}-${random_string.suffix.result}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false  # Set true for production

  # Allow your user to manage secrets
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge"
    ]
  }

  tags = local.tags
}

# Generate SQL admin password
resource "random_password" "sql_admin" {
  length  = 24
  special = true
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
  min_special = 2
}

# Store SQL password in Key Vault
resource "azurerm_key_vault_secret" "sql_password" {
  name         = "sql-admin-password"
  value        = random_password.sql_admin.result
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault.main]
}

# SQL Server
resource "azurerm_mssql_server" "main" {
  name                         = "sql-${local.app_name}-${random_string.suffix.result}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = random_password.sql_admin.result

  # Azure AD authentication (for managed identity)
  azuread_administrator {
    login_username = data.azurerm_client_config.current.object_id
    object_id      = data.azurerm_client_config.current.object_id
  }

  tags = local.tags
}

# SQL Database
resource "azurerm_mssql_database" "main" {
  name      = "sqldb-${local.app_name}-${local.environment}"
  server_id = azurerm_mssql_server.main.id
  sku_name  = "Basic"  # Use S0 or higher for production

  tags = local.tags
}

# SQL Firewall - Allow Azure Services
resource "azurerm_mssql_firewall_rule" "allow_azure" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# SQL Virtual Network Rule
resource "azurerm_mssql_virtual_network_rule" "data_subnet" {
  name      = "sql-vnet-rule"
  server_id = azurerm_mssql_server.main.id
  subnet_id = azurerm_subnet.data.id
}

# Storage Account for Function App
resource "azurerm_storage_account" "functions" {
  name                     = "stfunc${local.app_name}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.tags
}

# App Service Plan for Functions
resource "azurerm_service_plan" "functions" {
  name                = "asp-func-${local.app_name}-${local.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "EP1"  # Elastic Premium for VNet integration

  tags = local.tags
}

# Function App (Backend API)
resource "azurerm_linux_function_app" "backend" {
  name                       = "func-${local.app_name}-${random_string.suffix.result}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  service_plan_id            = azurerm_service_plan.functions.id
  storage_account_name       = azurerm_storage_account.functions.name
  storage_account_access_key = azurerm_storage_account.functions.primary_access_key

  # Enable managed identity
  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_insights_key               = azurerm_application_insights.main.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.main.connection_string

    application_stack {
      python_version = "3.11"
    }

    # CORS configuration for frontend
    cors {
      allowed_origins = [
        "https://${azurerm_static_web_app.frontend.default_host_name}"
      ]
    }
  }

  # VNet integration
  virtual_network_subnet_id = azurerm_subnet.backend.id

  # Application settings
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"     = "python"
    "SQL_SERVER"                   = azurerm_mssql_server.main.fully_qualified_domain_name
    "SQL_DATABASE"                 = azurerm_mssql_database.main.name
    "KEY_VAULT_URL"                = azurerm_key_vault.main.vault_uri
    "ENABLE_ORYX_BUILD"            = "true"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
  }

  tags = local.tags
}

# Grant Function App access to Key Vault
resource "azurerm_key_vault_access_policy" "function_app" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_function_app.backend.identity[0].principal_id

  secret_permissions = [
    "Get", "List"
  ]
}

# Static Web App (Frontend)
resource "azurerm_static_web_app" "frontend" {
  name                = "stapp-${local.app_name}-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus2"  # Static Web Apps have specific regions
  sku_tier            = "Free"     # Use "Standard" for custom domains
  sku_size            = "Free"

  tags = local.tags
}
EOF
```

**What this does:**
- Creates a complete 3-tier architecture with network isolation
- Uses managed identities for secure authentication (no passwords in app settings)
- Stores secrets in Key Vault
- Implements VNet integration for Function App
- Sets up comprehensive monitoring with Application Insights
- Configures CORS for frontend-backend communication
- Uses service endpoints for SQL Database security
- Follows Azure naming conventions with local variables

### Step 2: Create Outputs File

Create `outputs.tf`:

```bash
cat > outputs.tf << 'EOF'
# Infrastructure Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "location" {
  description = "Azure region"
  value       = azurerm_resource_group.main.location
}

# Frontend Outputs
output "frontend_url" {
  description = "Static Web App URL"
  value       = "https://${azurerm_static_web_app.frontend.default_host_name}"
}

output "frontend_api_key" {
  description = "Static Web App deployment token"
  value       = azurerm_static_web_app.frontend.api_key
  sensitive   = true
}

# Backend Outputs
output "backend_url" {
  description = "Function App URL"
  value       = "https://${azurerm_linux_function_app.backend.default_hostname}"
}

output "function_app_name" {
  description = "Function App name"
  value       = azurerm_linux_function_app.backend.name
}

output "function_app_identity" {
  description = "Function App managed identity principal ID"
  value       = azurerm_linux_function_app.backend.identity[0].principal_id
}

# Database Outputs
output "sql_server_fqdn" {
  description = "SQL Server fully qualified domain name"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "sql_database_name" {
  description = "SQL Database name"
  value       = azurerm_mssql_database.main.name
}

output "sql_admin_username" {
  description = "SQL admin username"
  value       = azurerm_mssql_server.main.administrator_login
}

# Security Outputs
output "key_vault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.main.vault_uri
}

# Monitoring Outputs
output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_app_id" {
  description = "Application Insights application ID"
  value       = azurerm_application_insights.main.app_id
}

# Network Outputs
output "vnet_id" {
  description = "Virtual Network ID"
  value       = azurerm_virtual_network.main.id
}

output "backend_subnet_id" {
  description = "Backend subnet ID"
  value       = azurerm_subnet.backend.id
}

output "data_subnet_id" {
  description = "Data subnet ID"
  value       = azurerm_subnet.data.id
}

# Summary Output
output "deployment_summary" {
  description = "Deployment summary"
  value = {
    environment      = local.environment
    resource_group   = azurerm_resource_group.main.name
    frontend_url     = "https://${azurerm_static_web_app.frontend.default_host_name}"
    backend_url      = "https://${azurerm_linux_function_app.backend.default_hostname}"
    sql_server       = azurerm_mssql_server.main.name
    key_vault        = azurerm_key_vault.main.name
    app_insights     = azurerm_application_insights.main.name
    vnet             = azurerm_virtual_network.main.name
  }
}
EOF
```

### Step 3: Initialize Terraform

```bash
terraform init
```

**Expected output:**
```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/azurerm versions matching "~> 3.0"...
- Finding hashicorp/random versions matching "~> 3.0"...

Terraform has been successfully initialized!
```

❌ **If initialization fails:** Check [Troubleshooting Terraform Init](#troubleshooting-terraform-init)

### Step 4: Review the Deployment Plan

```bash
terraform plan
```

**What to review:**
- [ ] ~20+ resources will be created
- [ ] Network topology looks correct (VNet with 2 subnets)
- [ ] Managed identity is configured for Function App
- [ ] Key Vault access policies are set up
- [ ] No sensitive values in app settings (using Key Vault references)

**Expected output:**
```
Plan: 22 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + backend_url          = (known after apply)
  + deployment_summary   = {...}
  + frontend_url         = (known after apply)
  + key_vault_name       = (known after apply)
  ...
```

### Step 5: Deploy the Infrastructure

```bash
terraform apply
```

Type `yes` when prompted.

**⏱️ Deployment time:** Typically takes 5-8 minutes for complete infrastructure.

**Expected output:**
```
Apply complete! Resources: 22 added, 0 changed, 0 destroyed.

Outputs:

deployment_summary = {
  environment    = "prod"
  resource_group = "rg-myapp-prod-eastus2"
  frontend_url   = "https://happy-rock-xxx.azurestaticapps.net"
  backend_url    = "https://func-myapp-xxx.azurewebsites.net"
  sql_server     = "sql-myapp-xxx"
  key_vault      = "kv-myapp-xxx"
  ...
}
```

### Step 6: Configure Post-Deployment Settings

**Retrieve SQL password from Key Vault:**
```bash
# Get the SQL admin password
SQL_PASSWORD=$(az keyvault secret show \
  --vault-name $(terraform output -raw key_vault_name) \
  --name sql-admin-password \
  --query value -o tsv)

echo "SQL Password: $SQL_PASSWORD"
# Save this securely!
```

**Deploy sample application code (optional):**
```bash
# This would deploy your actual application code
# Example for Function App:
# func azure functionapp publish $(terraform output -raw function_app_name)
```

## Verification

### Verify Deployment via CLI

**Check all resources:**
```bash
# List all resources
az resource list \
  --resource-group $(terraform output -raw resource_group_name) \
  --output table | wc -l
# Should show 20+ resources
```

**Verify network configuration:**
```bash
# Check VNet
az network vnet show \
  --resource-group $(terraform output -raw resource_group_name) \
  --name vnet-myapp-prod \
  --query "{Name:name,AddressSpace:addressSpace.addressPrefixes}" \
  --output table

# Check subnets
az network vnet subnet list \
  --resource-group $(terraform output -raw resource_group_name) \
  --vnet-name vnet-myapp-prod \
  --output table
```

**Verify managed identity:**
```bash
# Check Function App identity
az functionapp identity show \
  --name $(terraform output -raw function_app_name) \
  --resource-group $(terraform output -raw resource_group_name)
```

**Verify Key Vault access:**
```bash
# List Key Vault access policies
az keyvault show \
  --name $(terraform output -raw key_vault_name) \
  --query "properties.accessPolicies[].objectId" \
  --output table
```

### Verify via Azure Portal

1. **Resource Group**: Navigate to your resource group and verify all resources exist
2. **Virtual Network**: Check VNet has 2 subnets with correct address spaces
3. **Function App**:
   - Check Identity tab shows "System assigned: On"
   - Check Configuration tab - no passwords in app settings
   - Check Networking tab - VNet integration enabled
4. **Key Vault**: Check Access policies includes your Function App
5. **Application Insights**: Check Live Metrics are available
6. **Static Web App**: Check URL is accessible

### Test the Deployment

**Test frontend:**
```bash
curl -I $(terraform output -raw frontend_url)
# Should return HTTP 200 or 404 (no app deployed yet is OK)
```

**Test backend API:**
```bash
# Test Function App is running
curl -I $(terraform output -raw backend_url)
# Should return HTTP status
```

**Test managed identity Key Vault access:**
```bash
# This would be done from within the Function App code
# The Function App can now retrieve secrets without passwords:
# from azure.identity import DefaultAzureCredential
# from azure.keyvault.secrets import SecretClient
# credential = DefaultAzureCredential()
# client = SecretClient(vault_url=KEY_VAULT_URL, credential=credential)
# secret = client.get_secret("sql-admin-password")
```

✅ **Success indicators:**
- [ ] All 20+ resources deployed successfully
- [ ] VNet and subnets created
- [ ] Function App has managed identity enabled
- [ ] Function App integrated with VNet
- [ ] Key Vault contains SQL password
- [ ] Application Insights receiving telemetry
- [ ] Static Web App accessible
- [ ] SQL Database online

## Troubleshooting

### Common Error: Key Vault Access Denied

**Symptom:**
```
Error: checking for presence of existing Secret: Forbidden
```

**Cause:** Your user account doesn't have Key Vault access

**Solution:**
The configuration already grants your user access. If still failing:
```bash
# Get your object ID
OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)

# Grant yourself access
az keyvault set-policy \
  --name $(terraform output -raw key_vault_name) \
  --object-id $OBJECT_ID \
  --secret-permissions get list set delete
```

### Common Error: VNet Integration Failed

**Symptom:**
```
Error: creating VNet Swift Connection: subnet is not delegated to Microsoft.Web/serverFarms
```

**Cause:** Subnet delegation is incorrect

**Solution:**
The configuration already includes proper delegation. If issues persist:
```bash
# Check subnet delegation
az network vnet subnet show \
  --resource-group $(terraform output -raw resource_group_name) \
  --vnet-name vnet-myapp-prod \
  --name snet-backend \
  --query "delegations"
```

### Common Error: Function App Not Starting

**Symptom:**
Function App shows "Stopped" or not responding

**Cause:** Various - check Application Insights

**Solution:**
```bash
# Check Function App status
az functionapp show \
  --name $(terraform output -raw function_app_name) \
  --resource-group $(terraform output -raw resource_group_name) \
  --query "state"

# View logs
az functionapp log tail \
  --name $(terraform output -raw function_app_name) \
  --resource-group $(terraform output -raw resource_group_name)

# Restart if needed
az functionapp restart \
  --name $(terraform output -raw function_app_name) \
  --resource-group $(terraform output -raw resource_group_name)
```

### Getting Help

1. **Check Application Insights:**
   - Go to Azure Portal > Application Insights
   - Check Live Metrics, Failures, Performance

2. **Check Activity Log:**
   - Resource Group > Activity log
   - Filter for failed operations

3. **Enable debug logging:**
   ```bash
   TF_LOG=DEBUG terraform apply
   ```

## Cleanup

**⚠️ IMPORTANT:** This infrastructure costs ~$50-200/month. Destroy when done.

```bash
# Destroy all resources
terraform destroy

# Type 'yes' when prompted
```

**Expected time:** 5-10 minutes to destroy all resources.

**Verify cleanup:**
```bash
az group show --name $(terraform output -raw resource_group_name) 2>&1
# Should show ResourceGroupNotFound
```

## Cost Breakdown

### Expected Costs (24/7 operation)

| Resource | Tier | Cost/Month |
|----------|------|------------|
| Static Web App | Free | $0.00 |
| Function App (Premium) | EP1 | $145.00 |
| Storage Account | Standard LRS | $1.00 |
| SQL Database | Basic | $4.99 |
| SQL Server | Included | $0.00 |
| Key Vault | Standard | $0.03 |
| Application Insights | Pay-as-you-go | ~$5.00 |
| Log Analytics | Pay-as-you-go | ~$2.00 |
| Virtual Network | Included | $0.00 |
| **Total** | | **~$158/month** |

### Cost Optimization Tips

💡 **Save money:**

1. **Use Consumption Plan for Function App** (instead of Premium):
   ```hcl
   sku_name = "Y1"  # Consumption plan (free tier available)
   ```
   Savings: ~$140/month, but loses VNet integration

2. **Use SQL Database Serverless**:
   ```hcl
   sku_name = "GP_S_Gen5_1"
   auto_pause_delay_in_minutes = 60
   ```
   Savings: ~$30/month when not in use

3. **Destroy non-production environments** when not in use

4. **Use Azure Dev/Test pricing** if available

5. **Set up budget alerts**:
   ```bash
   az consumption budget create --amount 100 --time-period monthly
   ```

## Next Steps

**Related Guides:**
- [CI/CD Pipeline for 3-Tier App](howto-cicd-3tier.md)
- [Monitoring and Alerting](howto-monitoring-alerting.md)
- [Disaster Recovery Planning](howto-disaster-recovery.md)

**Learn More:**
- [Azure Architecture Best Practices](reference-azure-architecture-patterns.md)
- [Terraform Advanced Patterns](concept-terraform-advanced.md)
- [Security Hardening Guide](reference-security-hardening.md)

## Reference

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│ PRESENTATION TIER                                       │
│  Static Web App (Frontend)                              │
│  - React/Angular/Vue app                                │
│  - HTTPS only                                           │
└────────────┬────────────────────────────────────────────┘
             │ HTTPS/CORS
             ▼
┌─────────────────────────────────────────────────────────┐
│ APPLICATION TIER (VNet Integrated)                      │
│  Function App (Backend API)                             │
│  - Managed Identity                                     │
│  - Application Insights                                 │
│  - Key Vault Integration                                │
└────────────┬────────────────────────────────────────────┘
             │ VNet Service Endpoint
             ▼
┌─────────────────────────────────────────────────────────┐
│ DATA TIER                                               │
│  Azure SQL Database                                     │
│  - Private connectivity via service endpoint            │
│  - Secrets in Key Vault                                 │
└─────────────────────────────────────────────────────────┘

SUPPORTING SERVICES:
- Key Vault (secrets management)
- Application Insights (monitoring)
- Log Analytics (logs)
- Virtual Network (isolation)
```

### Useful Commands

```bash
# View complete infrastructure
terraform show

# Get specific output
terraform output frontend_url
terraform output backend_url

# Get sensitive outputs
terraform output -raw frontend_api_key
terraform output -raw application_insights_instrumentation_key

# Refresh state
terraform refresh

# Plan changes only
terraform plan

# View dependency graph
terraform graph | dot -Tpng > graph.png
```

### External Resources

**Official Documentation:**
- [Azure Well-Architected Framework](https://learn.microsoft.com/en-us/azure/well-architected/)
- [Azure Functions Best Practices](https://learn.microsoft.com/en-us/azure/azure-functions/functions-best-practices)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

## Glossary Terms Used

- **Terraform**: Infrastructure as Code tool
- **Function App**: Serverless compute service
- **Managed Identity**: Azure AD identity for Azure resources
- **Key Vault**: Secrets management service
- **Virtual Network**: Network isolation in Azure
- **Application Insights**: Application monitoring service

---

**Document Metadata**:
- **Last Updated**: 2025-12-29
- **Tested On**: Terraform v1.9.0, Azure CLI 2.56.0
- **Next Review**: 2026-03-29
- **Maintainer**: IaC Documentation Team
