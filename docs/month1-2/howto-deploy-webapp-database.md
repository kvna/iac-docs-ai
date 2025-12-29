---
document_id: howto-deploy-webapp-database
document_type: howto
skill_level: month1-2
topics: [deployment, operations, azure, web-app, database]
technologies: [terraform_v1.5+, azure_cli_2.50+, azure_app_service, azure_sql]
prerequisites:
  - "Azure account with appropriate permissions"
  - "Terraform installed (v1.5+)"
  - "Azure CLI installed and configured"
  - "Completed howto-deploy-azure-resource-group"
  - "Understanding of web applications and databases"
learning_outcomes:
  - Successfully deploy a Web App with SQL Database to Azure
  - Configure database connection strings securely
  - Understand resource dependencies in Terraform
  - Verify multi-tier deployment is working correctly
  - Manage secrets and connection strings properly
estimated_time: 30
last_reviewed: 2025-12-29
review_status: current
search_keywords:
  - "how to deploy web app with database to azure"
  - "azure web app sql database terraform"
  - "deploy app service with database terraform"
  - "azure app service deployment guide"
  - "terraform web app database tutorial"
related_documents:
  - concept-iac-overview
  - howto-deploy-azure-resource-group
  - concept-terraform-workflow
  - reference-terraform-best-practices
glossary_terms:
  - terraform
  - azure
  - app-service
  - sql-database
  - resource-group
  - connection-string
---

# How to Deploy a Web App with Database

## Overview

**Purpose**: Provide step-by-step instructions to deploy an Azure Web App connected to an Azure SQL Database using Terraform. This intermediate guide demonstrates multi-resource deployments with dependencies.

**What You'll Deploy**:
- Azure Resource Group (logical container)
- Azure App Service Plan (hosting plan for web app)
- Azure Web App (App Service for hosting your application)
- Azure SQL Server (database server)
- Azure SQL Database (actual database)
- Secure connection string configuration

**Estimated Time**: 30 minutes

**Estimated Cost**:
- Development (Basic tier): ~$15/month
- Production (Standard tier): ~$75/month
- Can run on free tier: Partially (App Service F1 free, but SQL requires Basic $5/month minimum)

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
- [ ] Service quotas: App Service plan quota (usually no issues)

### Required Knowledge

Before starting, you should understand:
- [ ] Basic terminal/command line usage
- [ ] What a web application is and how it connects to databases
- [ ] How to authenticate with Azure CLI
- [ ] Basic Terraform syntax and workflow (plan/apply/destroy)
- [ ] What resource dependencies are in Terraform

**New to these concepts?** Complete these guides first:
- [What is Infrastructure as Code?](../day1/concept-iac-overview.md)
- [How to Deploy Azure Resource Group](../day1/howto-deploy-azure-resource-group.md)

## Before You Begin

### Step 1: Verify Tool Installation

Run each command and verify the output:

```bash
# Check Terraform
terraform version
```

**Expected output:**
```
Terraform v1.5.0 or higher
```

```bash
# Check Azure CLI
az version
```

**Expected output:**
```
azure-cli 2.50.0 or higher
```

❌ **If any tool is missing:** Install it following the [Environment Setup Guide](../day1/howto-environment-setup.md)

### Step 2: Authenticate to Azure

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "YOUR-SUBSCRIPTION-NAME"

# Verify you're logged in
az account show
```

**Expected output:**
```json
{
  "id": "your-subscription-id",
  "name": "Your Subscription Name",
  "state": "Enabled"
}
```

❌ **If authentication fails:** Check [Troubleshooting Authentication](#troubleshooting-authentication)

### Step 3: Create Working Directory

```bash
# Create project directory
mkdir -p ~/terraform-projects/webapp-database
cd ~/terraform-projects/webapp-database

# Verify you're in the right place
pwd
```

**Expected output:**
```
/home/[your-username]/terraform-projects/webapp-database
```

## Deployment Steps

### Step 1: Create Terraform Configuration

Create a file named `main.tf`:

```bash
cat > main.tf << 'EOF'
# Configure the Azure Provider
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
  features {}
}

# Generate random password for SQL admin
resource "random_password" "sql_admin_password" {
  length  = 24
  special = true
  # Ensure password meets Azure SQL complexity requirements
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
  min_special = 2
}

# Create Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-webapp-dev-eastus2"
  location = "eastus2"

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
    Purpose     = "Web App with Database POC"
    Owner       = "your-name"
  }
}

# Create App Service Plan
resource "azurerm_service_plan" "main" {
  name                = "asp-webapp-dev-eastus2"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "B1" # Basic tier - $13/month

  tags = azurerm_resource_group.main.tags
}

# Create Web App
resource "azurerm_linux_web_app" "main" {
  name                = "app-mywebapp-dev-${random_password.sql_admin_password.id}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    always_on = false # Set to true for production

    application_stack {
      # Example: Python 3.11 - change based on your app
      python_version = "3.11"
    }
  }

  # Configure database connection string
  app_settings = {
    "DATABASE_SERVER"   = azurerm_mssql_server.main.fully_qualified_domain_name
    "DATABASE_NAME"     = azurerm_mssql_database.main.name
    "DATABASE_USER"     = azurerm_mssql_server.main.administrator_login
    "DATABASE_PASSWORD" = azurerm_mssql_server.main.administrator_login_password
  }

  connection_string {
    name  = "DefaultConnection"
    type  = "SQLAzure"
    value = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.main.name};Persist Security Info=False;User ID=${azurerm_mssql_server.main.administrator_login};Password=${azurerm_mssql_server.main.administrator_login_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  }

  tags = azurerm_resource_group.main.tags
}

# Create SQL Server
resource "azurerm_mssql_server" "main" {
  name                         = "sql-webapp-dev-${random_password.sql_admin_password.id}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = random_password.sql_admin_password.result

  tags = azurerm_resource_group.main.tags
}

# Create SQL Database
resource "azurerm_mssql_database" "main" {
  name      = "sqldb-webapp-dev"
  server_id = azurerm_mssql_server.main.id
  sku_name  = "Basic" # $5/month - smallest paid tier

  # Prevent accidental deletion in production
  # lifecycle {
  #   prevent_destroy = true
  # }

  tags = azurerm_resource_group.main.tags
}

# Allow Azure services to access SQL Server
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Optional: Allow your IP to access SQL Server for testing
# Uncomment and replace with your IP
# resource "azurerm_mssql_firewall_rule" "allow_my_ip" {
#   name             = "AllowMyIP"
#   server_id        = azurerm_mssql_server.main.id
#   start_ip_address = "YOUR.IP.ADDRESS.HERE"
#   end_ip_address   = "YOUR.IP.ADDRESS.HERE"
# }
EOF
```

**What this does:**
- Creates a resource group for all resources
- Generates a secure random password for SQL admin (meets Azure complexity requirements)
- Creates an App Service Plan (Linux-based, Basic tier)
- Creates a Web App configured for Python 3.11 (you can change this)
- Creates a SQL Server with the generated admin password
- Creates a SQL Database (Basic tier - smallest paid option)
- Configures database connection string in the Web App
- Allows Azure services to access the SQL Server (required for App Service connection)
- Uses `random_password.sql_admin_password.id` to ensure globally unique names

**Important notes:**
- SQL Server and Web App names must be globally unique across Azure
- The random password is stored in Terraform state (use Azure Key Vault for production)
- Basic tier is lowest cost option for learning

### Step 2: Create Outputs File

Create a file named `outputs.tf`:

```bash
cat > outputs.tf << 'EOF'
# Outputs to display after deployment
output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "web_app_name" {
  description = "The name of the web app"
  value       = azurerm_linux_web_app.main.name
}

output "web_app_url" {
  description = "The default URL of the web app"
  value       = "https://${azurerm_linux_web_app.main.default_hostname}"
}

output "sql_server_name" {
  description = "The name of the SQL server"
  value       = azurerm_mssql_server.main.name
}

output "sql_server_fqdn" {
  description = "The fully qualified domain name of the SQL server"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "database_name" {
  description = "The name of the database"
  value       = azurerm_mssql_database.main.name
}

output "sql_admin_username" {
  description = "The SQL admin username"
  value       = azurerm_mssql_server.main.administrator_login
}

output "sql_admin_password" {
  description = "The SQL admin password"
  value       = azurerm_mssql_server.main.administrator_login_password
  sensitive   = true
}

output "connection_string" {
  description = "Database connection string"
  value       = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.main.name};User ID=${azurerm_mssql_server.main.administrator_login};Password=<PASSWORD_HERE>;"
  sensitive   = false
}
EOF
```

**What this does:**
- Defines output values for all important resources
- Marks the password as sensitive (won't display in console by default)
- Provides the web app URL for easy access
- Provides connection string template

### Step 3: Initialize Terraform

```bash
terraform init
```

**What this does:**
- Downloads Azure provider plugin (azurerm)
- Downloads random provider plugin (for password generation)
- Initializes the backend
- Prepares your working directory

**Expected output:**
```
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/azurerm versions matching "~> 3.0"...
- Finding hashicorp/random versions matching "~> 3.0"...
- Installing hashicorp/azurerm v3.85.0...
- Installing hashicorp/random v3.6.0...

Terraform has been successfully initialized!
```

❌ **If initialization fails:** Check [Troubleshooting Terraform Init](#troubleshooting-terraform-init)

### Step 4: Review the Deployment Plan

```bash
terraform plan
```

**What this does:**
- Shows all resources Terraform will create
- Validates configuration syntax
- Checks for errors before deploying
- Shows resource dependencies

**Expected output:**
```
Terraform will perform the following actions:

  # azurerm_linux_web_app.main will be created
  # azurerm_mssql_database.main will be created
  # azurerm_mssql_firewall_rule.allow_azure_services will be created
  # azurerm_mssql_server.main will be created
  # azurerm_resource_group.main will be created
  # azurerm_service_plan.main will be created
  # random_password.sql_admin_password will be created

Plan: 7 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + connection_string    = (sensitive value)
  + database_name        = "sqldb-webapp-dev"
  + resource_group_name  = "rg-webapp-dev-eastus2"
  + sql_admin_password   = (sensitive value)
  + sql_admin_username   = "sqladmin"
  + sql_server_fqdn      = (known after apply)
  + sql_server_name      = (known after apply)
  + web_app_name         = (known after apply)
  + web_app_url          = (known after apply)
```

**Review the plan carefully:**
- [ ] 7 resources will be created (1 random password + 6 Azure resources)
- [ ] Resource names follow naming conventions
- [ ] No unexpected changes or deletions
- [ ] Connection string will be configured

### Step 5: Deploy the Resources

```bash
terraform apply
```

**What this does:**
- Creates all resources in Azure in the correct order
- Terraform automatically handles dependencies:
  1. Resource Group first
  2. Random password
  3. SQL Server (needs resource group + password)
  4. App Service Plan (needs resource group)
  5. SQL Database (needs SQL Server)
  6. Web App (needs App Service Plan)
  7. Firewall Rule (needs SQL Server)
- Shows progress as each resource is created
- Displays output values when complete

**When prompted:**
```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:
```

Type `yes` and press Enter.

**Expected output:**
```
random_password.sql_admin_password: Creating...
random_password.sql_admin_password: Creation complete after 0s
azurerm_resource_group.main: Creating...
azurerm_resource_group.main: Creation complete after 2s
azurerm_mssql_server.main: Creating...
azurerm_service_plan.main: Creating...
azurerm_service_plan.main: Creation complete after 15s
azurerm_mssql_server.main: Still creating... [10s elapsed]
azurerm_mssql_server.main: Creation complete after 45s
azurerm_mssql_database.main: Creating...
azurerm_linux_web_app.main: Creating...
azurerm_mssql_firewall_rule.allow_azure_services: Creating...
azurerm_mssql_firewall_rule.allow_azure_services: Creation complete after 3s
azurerm_mssql_database.main: Still creating... [10s elapsed]
azurerm_linux_web_app.main: Still creating... [10s elapsed]
azurerm_mssql_database.main: Creation complete after 15s
azurerm_linux_web_app.main: Creation complete after 30s

Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

Outputs:

connection_string = <sensitive>
database_name = "sqldb-webapp-dev"
resource_group_name = "rg-webapp-dev-eastus2"
sql_admin_password = <sensitive>
sql_admin_username = "sqladmin"
sql_server_fqdn = "sql-webapp-dev-abc123.database.windows.net"
sql_server_name = "sql-webapp-dev-abc123"
web_app_name = "app-mywebapp-dev-abc123"
web_app_url = "https://app-mywebapp-dev-abc123.azurewebsites.net"
```

**⏱️ Deployment time:** Typically takes 2-3 minutes.

### Step 6: Save Important Values

Copy these values for later use:

```bash
# Display all outputs (sensitive values hidden)
terraform output

# Display sensitive values
terraform output sql_admin_password
terraform output connection_string
```

**Save these values securely:**
```
Web App URL: For accessing your application
SQL Server FQDN: For database connections
SQL Admin Username: For database administration
SQL Admin Password: KEEP THIS SECURE - needed for database access
Connection String: For configuring your application
```

## Verification

### Verify Deployment via CLI

**Check all resources exist:**
```bash
# List all resources in the resource group
az resource list --resource-group rg-webapp-dev-eastus2 --output table

# Check Web App status
az webapp show --name $(terraform output -raw web_app_name) \
  --resource-group $(terraform output -raw resource_group_name) \
  --query "{Name:name,State:state,DefaultHostName:defaultHostName}" \
  --output table

# Check SQL Server
az sql server show --name $(terraform output -raw sql_server_name) \
  --resource-group $(terraform output -raw resource_group_name) \
  --query "{Name:name,State:state,FQDN:fullyQualifiedDomainName}" \
  --output table

# Check SQL Database
az sql db show --name $(terraform output -raw database_name) \
  --server $(terraform output -raw sql_server_name) \
  --resource-group $(terraform output -raw resource_group_name) \
  --query "{Name:name,Status:status,ServiceObjective:currentServiceObjectiveName}" \
  --output table
```

**Expected output:**
All resources should show "Running" or "Online" status.

### Verify via Azure Portal

1. **Azure Portal**: https://portal.azure.com
   - Navigate to: Resource groups > rg-webapp-dev-eastus2
   - You should see: 4 resources (App Service Plan, Web App, SQL Server, SQL Database)
   - Click on each to verify configuration

2. **Web App**:
   - Navigate to: App Services > [your-app-name]
   - Check: Overview shows "Running"
   - Check: Configuration > Application settings shows database connection values
   - Check: Configuration > Connection strings shows "DefaultConnection"

3. **SQL Database**:
   - Navigate to: SQL databases > sqldb-webapp-dev
   - Check: Overview shows "Online"
   - Check: Compute + storage shows "Basic" tier
   - Check: Firewall and virtual networks shows "Allow Azure services" rule

### Test the Deployment

**Test Web App is accessible:**
```bash
# Get the web app URL
WEB_APP_URL=$(terraform output -raw web_app_url)

# Test the web app (should return default page)
curl -I $WEB_APP_URL
```

**Expected result:**
```
HTTP/2 200
# Or HTTP/2 404 if no app is deployed yet (that's OK - infrastructure is ready)
```

**Test Database Connection (using Azure Cloud Shell or local with SQL tools):**
```bash
# Get connection details
SQL_SERVER=$(terraform output -raw sql_server_fqdn)
SQL_USER=$(terraform output -raw sql_admin_username)
SQL_PASS=$(terraform output -raw sql_admin_password)
DB_NAME=$(terraform output -raw database_name)

# Test connection using sqlcmd (if installed)
sqlcmd -S $SQL_SERVER -U $SQL_USER -P "$SQL_PASS" -d $DB_NAME -Q "SELECT @@VERSION"
```

**Expected result:**
Should return SQL Server version information.

✅ **Success indicators:**
- [ ] Web App shows "Running" status
- [ ] Web App URL is accessible (returns 200 or 404)
- [ ] SQL Server is "Online"
- [ ] SQL Database is "Online"
- [ ] Can connect to database (if tested)
- [ ] Connection string is configured in Web App

## Troubleshooting

### Common Error: SQL Server Name Already Taken

**Symptom:**
```
Error: creating SQL Server: sql.ServersClient#CreateOrUpdate: Failure sending request:
StatusCode=0 -- Original Error: autorest/azure: Service returned an error.
Status=<nil> Code="ServerNameNotAvailable"
Message="The server name is already taken"
```

**Cause:** SQL Server names must be globally unique across all Azure

**Solution:**
The configuration uses a random suffix to avoid this. If it still happens:
```bash
# Re-run terraform apply - it will generate a new random password/suffix
terraform apply
```

### Common Error: SQL Password Complexity Requirements

**Symptom:**
```
Error: creating SQL Server: sql.ServersClient#CreateOrUpdate:
Password validation failed. The password does not meet policy requirements
```

**Cause:** Azure SQL requires complex passwords (uppercase, lowercase, numbers, special characters)

**Solution:**
The configuration uses `random_password` with complexity requirements. If you're setting your own password, ensure it meets:
- At least 16 characters
- At least 1 uppercase letter
- At least 1 lowercase letter
- At least 1 number
- At least 1 special character

### Common Error: App Service Plan Quota Exceeded

**Symptom:**
```
Error: creating App Service Plan: web.AppServicePlansClient#CreateOrUpdate:
Failure sending request: StatusCode=409
Code="QuotaExceeded"
```

**Cause:** Free/Basic tier has limits on number of instances per subscription

**Solution:**
```bash
# List existing app service plans
az appservice plan list --output table

# Delete unused plans or use a different region
az appservice plan delete --name <unused-plan> --resource-group <rg>
```

### Common Error: Cannot Connect to SQL Server

**Symptom:**
Cannot connect to SQL Server from local machine

**Cause:** SQL Server firewall doesn't allow your IP

**Solution:**
```bash
# Get your public IP
MY_IP=$(curl -s https://api.ipify.org)

# Add firewall rule
az sql server firewall-rule create \
  --resource-group $(terraform output -raw resource_group_name) \
  --server $(terraform output -raw sql_server_name) \
  --name AllowMyIP \
  --start-ip-address $MY_IP \
  --end-ip-address $MY_IP
```

Or uncomment the firewall rule in main.tf and run `terraform apply`.

### Troubleshooting Authentication

**Problem:** CLI authentication fails

**Solution:**
```bash
# Clear cached credentials
az account clear

# Re-login
az login

# List subscriptions
az account list --output table

# Set correct subscription
az account set --subscription "YOUR-SUBSCRIPTION-NAME"
```

### Troubleshooting Terraform Init

**Problem:** Provider download fails

**Solution:**
```bash
# Clear Terraform cache
rm -rf .terraform
rm -f .terraform.lock.hcl

# Retry initialization
terraform init
```

### Getting Help

If you encounter issues not covered here:

1. **Check Terraform state:**
   ```bash
   terraform show
   ```

2. **View detailed logs:**
   ```bash
   TF_LOG=DEBUG terraform apply
   ```

3. **Check Azure Activity Log:**
   - Go to Azure Portal
   - Navigate to: Resource Group > Activity log
   - Look for failed operations

4. **Validate connection string:**
   ```bash
   terraform output connection_string
   ```

5. **Ask for help:**
   - Include error message (remove passwords)
   - Include Terraform version: `terraform version`
   - Include Azure CLI version: `az version`

## Cleanup

**⚠️ IMPORTANT:** Running resources incur costs (~$18/month). Clean up when done testing.

### Destroy All Resources

```bash
# Show what will be deleted
terraform plan -destroy

# Delete all resources
terraform destroy
```

**When prompted:**
```
Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value:
```

Type `yes` and press Enter.

**Expected output:**
```
azurerm_mssql_firewall_rule.allow_azure_services: Destroying...
azurerm_linux_web_app.main: Destroying...
azurerm_mssql_database.main: Destroying...
azurerm_mssql_firewall_rule.allow_azure_services: Destruction complete after 2s
azurerm_linux_web_app.main: Still destroying... [10s elapsed]
azurerm_mssql_database.main: Still destroying... [10s elapsed]
azurerm_linux_web_app.main: Destruction complete after 15s
azurerm_mssql_database.main: Destruction complete after 20s
azurerm_mssql_server.main: Destroying...
azurerm_service_plan.main: Destroying...
azurerm_service_plan.main: Destruction complete after 5s
azurerm_mssql_server.main: Still destroying... [10s elapsed]
azurerm_mssql_server.main: Destruction complete after 15s
azurerm_resource_group.main: Destroying...
azurerm_resource_group.main: Still destroying... [10s elapsed]
azurerm_resource_group.main: Destruction complete after 45s
random_password.sql_admin_password: Destroying...
random_password.sql_admin_password: Destruction complete after 0s

Destroy complete! Resources: 7 destroyed.
```

### Verify Cleanup

**Check via CLI:**
```bash
# Try to list resources (should return empty)
az resource list --resource-group rg-webapp-dev-eastus2
```

**Expected:**
```
Resource group 'rg-webapp-dev-eastus2' could not be found.
```

**Check via Portal:**
- Verify resource group is deleted
- Check for any orphaned resources

### Clean Up Local Files (Optional)

```bash
# Remove Terraform state files
rm -rf .terraform
rm terraform.tfstate*
rm .terraform.lock.hcl

# Remove configuration files (if you're done)
cd ..
rm -rf webapp-database
```

## Cost Breakdown

### Expected Costs

**If you run this 24/7:**

| Resource | Tier | Cost/Month |
|----------|------|------------|
| App Service Plan | B1 (Basic) | $13.14 |
| Web App | Included | $0.00 |
| SQL Server | Included | $0.00 |
| SQL Database | Basic (2GB) | $4.99 |
| **Total** | | **~$18/month** |

**If you only run during business hours (8hrs/day, 5days/week):**
- Not applicable - SQL Database bills 24/7 even if unused
- App Service can scale to F1 (free) for testing
- Approximate: $5/month (database only)

**Free tier option:**
- App Service: F1 (free) - limited to 60 minutes/day compute
- SQL Database: No free tier available (minimum $4.99/month)

### Saving Money

💡 **Cost optimization tips:**
- Destroy when not in use (re-deploy takes 2-3 minutes)
- Use Azure SQL Database serverless for dev (auto-pause when idle)
- Scale down to F1 App Service tier for testing
- Use shared resources in dev environments
- Set up budget alerts in Azure Cost Management

**To change to cheaper tiers in main.tf:**
```hcl
# App Service Plan - FREE tier
sku_name = "F1"  # Instead of "B1"

# SQL Database - DTU-based serverless (auto-pause)
# Replace the database resource with:
resource "azurerm_mssql_database" "main" {
  name      = "sqldb-webapp-dev"
  server_id = azurerm_mssql_server.main.id

  sku_name                    = "GP_S_Gen5_1"  # Serverless
  min_capacity                = 0.5
  max_size_gb                 = 2
  auto_pause_delay_in_minutes = 60  # Pause after 1 hour idle
}
```

## Next Steps

Now that you've successfully deployed a web app with database, you might want to:

**Related Guides:**
- [How to Deploy 3-Tier Application](../month3-6/howto-deploy-3tier-application.md) - Advanced multi-tier deployment
- [How to Configure CI/CD for Web App](../month3-6/howto-webapp-cicd.md) - Automated deployments
- [How to Secure Connection Strings with Key Vault](../month3-6/howto-keyvault-secrets.md) - Production-ready secrets management

**Learn More:**
- [Understanding Resource Dependencies in Terraform](../month1-2/concept-terraform-dependencies.md) - How Terraform manages resource order
- [Azure SQL Database Best Practices](../month3-6/reference-azure-sql-best-practices.md) - Security and performance tuning
- [Terraform State Management](../month1-2/concept-terraform-state.md) - Managing state files securely

## Reference

### Complete Terraform Configuration

See the files created in deployment steps above. Full configuration includes:
- `main.tf`: All resource definitions
- `outputs.tf`: Output values

### Useful Commands

```bash
# View current state
terraform show

# List all resources
terraform state list

# Get all outputs
terraform output

# Get specific output
terraform output web_app_url
terraform output -raw sql_admin_password

# Format code
terraform fmt

# Validate configuration
terraform validate

# Refresh state from Azure
terraform refresh

# Taint a resource for recreation
terraform taint azurerm_linux_web_app.main
```

### External Resources

**Official Documentation:**
- [Azure App Service Overview](https://learn.microsoft.com/en-us/azure/app-service/overview)
- [Azure SQL Database Documentation](https://learn.microsoft.com/en-us/azure/azure-sql/database/)
- [Terraform Azure Provider - App Service](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_web_app)
- [Terraform Azure Provider - SQL Database](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_database)

**Community Resources:**
- [Azure App Service + SQL Database Tutorial](https://learn.microsoft.com/en-us/azure/app-service/tutorial-dotnetcore-sqldb-app)
- [Terraform Azure Examples](https://github.com/hashicorp/terraform-provider-azurerm/tree/main/examples)

## Glossary Terms Used

All terms below are defined in the [Glossary](../../config/glossary.yaml):

- **Terraform**: Open-source Infrastructure as Code tool
- **Azure**: Microsoft's cloud computing platform
- **App Service**: Azure's Platform-as-a-Service (PaaS) for hosting web applications
- **SQL Database**: Azure's managed relational database service
- **Resource Group**: Logical container for Azure resources
- **Connection String**: Configuration string containing database connection details

---

**Document Metadata**:
- **Last Updated**: 2025-12-29
- **Tested On**: Terraform v1.9.0, Azure CLI 2.56.0
- **Next Review**: 2026-03-29
- **Maintainer**: IaC Documentation Team
