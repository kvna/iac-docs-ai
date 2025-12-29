---
document_id: howto-deploy-azure-resource-group
document_type: howto
skill_level: day1
topics: [deployment, operations, azure, resource-group]
technologies: [terraform_v1.5+, azure_cli_2.50+]
prerequisites:
  - "Azure account with appropriate permissions"
  - "Terraform installed (v1.5+)"
  - "Azure CLI installed and configured"
learning_outcomes:
  - Successfully deploy an Azure Resource Group using Terraform
  - Verify the deployment is working correctly
  - Understand how to troubleshoot common issues
  - Know how to clean up resources to avoid costs
estimated_time: 10
last_reviewed: 2025-12-29
review_status: current
search_keywords:
  - "how to deploy resource group to azure"
  - "azure resource group terraform deployment"
  - "step by step resource group deployment"
  - "create azure resource group with terraform"
  - "terraform azure resource group guide"
related_documents:
  - concept-iac-overview
  - howto-environment-setup
  - concept-terraform-workflow
glossary_terms:
  - terraform
  - azure
  - resource-group
  - iac
---

# How to Deploy an Azure Resource Group

## Overview

**Purpose**: Provide step-by-step instructions to deploy an Azure Resource Group to Azure using Terraform. This is your first hands-on deployment - a simple, foundational task to get you started with Infrastructure as Code.

**What You'll Deploy**:
- A single Azure Resource Group (a logical container for Azure resources)
- Configured with proper naming conventions and tags
- Ready to hold future Azure resources

**Estimated Time**: 10 minutes

**Estimated Cost**:
- Resource Groups are completely free: $0/month
- You only pay for resources you put inside them

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
- [ ] Service quotas: None (resource groups don't count against quotas)

### Required Knowledge

Before starting, you should understand:
- [ ] Basic terminal/command line usage
- [ ] What a resource group is and why you'd use it
- [ ] How to authenticate with Azure CLI

**New to these concepts?** Read [What is Infrastructure as Code?](concept-iac-overview.md) first.

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

❌ **If any tool is missing:** Install it following the [Environment Setup Guide](howto-environment-setup.md)

### Step 2: Authenticate to Azure

```bash
# Login to Azure
az login

# List your subscriptions
az account list --output table

# Set your subscription (replace with your subscription name or ID)
az account set --subscription "YOUR-SUBSCRIPTION-NAME"

# Verify you're logged in
az account show
```

**Expected output:**
```json
{
  "environmentName": "AzureCloud",
  "id": "your-subscription-id",
  "name": "Your Subscription Name",
  "state": "Enabled",
  "user": {
    "name": "your-email@example.com",
    "type": "user"
  }
}
```

❌ **If authentication fails:** Check [Troubleshooting Authentication](#troubleshooting-authentication)

### Step 3: Create Working Directory

```bash
# Create project directory
mkdir -p ~/terraform-projects/azure-resource-group
cd ~/terraform-projects/azure-resource-group

# Verify you're in the right place
pwd
```

**Expected output:**
```
/home/[your-username]/terraform-projects/azure-resource-group
```

## Deployment Steps

### Step 1: Create Terraform Configuration

Create a file named `main.tf`:

```bash
# Create the file
cat > main.tf << 'EOF'
# Configure the Azure Provider
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Create a Resource Group
resource "azurerm_resource_group" "example" {
  name     = "rg-myapp-dev-eastus2"
  location = "eastus2"

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
    Purpose     = "Learning IaC"
    Owner       = "your-name"
  }
}
EOF
```

**What this does:**
- Configures Terraform to use Azure provider version 3.x
- Creates a resource group named `rg-myapp-dev-eastus2` in East US 2 region
- Adds tags for organization and tracking
- Follows Azure naming conventions: `rg-[workload]-[environment]-[region]`

**Customize these values:**
- `name`: Change `myapp` to your application name
- `location`: Change to your preferred region (e.g., `westus2`, `northeurope`)
- `tags.Owner`: Change to your name

### Step 2: Create Outputs File (Optional but Recommended)

Create a file named `outputs.tf`:

```bash
cat > outputs.tf << 'EOF'
# Outputs to display after deployment
output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.example.name
}

output "resource_group_location" {
  description = "The location of the resource group"
  value       = azurerm_resource_group.example.location
}

output "resource_group_id" {
  description = "The ID of the resource group"
  value       = azurerm_resource_group.example.id
}
EOF
```

**What this does:**
- Defines output values that will be displayed after deployment
- Makes it easy to reference the resource group in future deployments

### Step 3: Initialize Terraform

```bash
terraform init
```

**What this does:**
- Downloads the Azure provider plugin (hashicorp/azurerm)
- Initializes the backend (local state by default)
- Prepares your working directory for deployment

**Expected output:**
```
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/azurerm versions matching "~> 3.0"...
- Installing hashicorp/azurerm v3.85.0...
- Installed hashicorp/azurerm v3.85.0

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure.
```

❌ **If initialization fails:** Check [Troubleshooting Terraform Init](#troubleshooting-terraform-init)

### Step 4: Review the Deployment Plan

```bash
terraform plan
```

**What this does:**
- Shows what Terraform will create
- Validates your configuration syntax
- Checks for errors before deploying

**Expected output:**
```
Terraform used the selected providers to generate the following execution plan.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # azurerm_resource_group.example will be created
  + resource "azurerm_resource_group" "example" {
      + id       = (known after apply)
      + location = "eastus2"
      + name     = "rg-myapp-dev-eastus2"
      + tags     = {
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Owner"       = "your-name"
          + "Purpose"     = "Learning IaC"
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + resource_group_id       = (known after apply)
  + resource_group_location = "eastus2"
  + resource_group_name     = "rg-myapp-dev-eastus2"
```

**Review the plan carefully:**
- [ ] Resource name matches what you expect
- [ ] Location is correct
- [ ] Tags are set properly
- [ ] Shows "1 to add, 0 to change, 0 to destroy"

### Step 5: Deploy the Resource Group

```bash
terraform apply
```

**What this does:**
- Creates the resource group in Azure
- Shows progress as the resource is created
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
azurerm_resource_group.example: Creating...
azurerm_resource_group.example: Creation complete after 2s [id=/subscriptions/your-sub-id/resourceGroups/rg-myapp-dev-eastus2]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

resource_group_id = "/subscriptions/your-sub-id/resourceGroups/rg-myapp-dev-eastus2"
resource_group_location = "eastus2"
resource_group_name = "rg-myapp-dev-eastus2"
```

**⏱️ Deployment time:** Typically takes 2-5 seconds.

### Step 6: Save Important Values

Copy these values for later use:

```bash
# Display all outputs
terraform output
```

**Save these values:**
```
resource_group_name = Name you'll use for future deployments
resource_group_location = Region where your resources will live
resource_group_id = Full Azure resource identifier
```

## Verification

### Verify Deployment via CLI

**Check resource group exists:**
```bash
# List all resource groups
az group list --output table

# Show specific resource group
az group show --name rg-myapp-dev-eastus2 --output json
```

**Expected output:**
```json
{
  "id": "/subscriptions/your-sub-id/resourceGroups/rg-myapp-dev-eastus2",
  "location": "eastus2",
  "name": "rg-myapp-dev-eastus2",
  "properties": {
    "provisioningState": "Succeeded"
  },
  "tags": {
    "Environment": "dev",
    "ManagedBy": "terraform",
    "Owner": "your-name",
    "Purpose": "Learning IaC"
  }
}
```

### Verify via Azure Portal

1. **Azure Portal**: https://portal.azure.com
   - Navigate to: Home > Resource groups
   - You should see: Your resource group `rg-myapp-dev-eastus2` in the list
   - Click on it to see the details and tags

### Test the Deployment

Verify you can use the resource group:

```bash
# Try to list resources in the resource group (should be empty)
az resource list --resource-group rg-myapp-dev-eastus2 --output table
```

**Expected result:**
```
(Empty - no resources deployed yet)
```

This is correct - the resource group is empty and ready to hold future resources.

✅ **Success indicators:**
- [ ] Resource group appears in Azure Portal
- [ ] Tags are set correctly
- [ ] Location matches what you specified
- [ ] `provisioningState` is "Succeeded"

## Troubleshooting

### Common Error: Insufficient Permissions

**Symptom:**
```
Error: authorization failed: "your-email@example.com" does not have authorization to perform action "Microsoft.Resources/subscriptions/resourceGroups/write"
```

**Cause:** Your Azure account doesn't have permission to create resource groups

**Solution:**
1. Contact your Azure administrator
2. Ask for "Contributor" or "Owner" role on the subscription
3. Or ask them to create a resource group for you and give you "Contributor" access to it

### Common Error: Resource Group Already Exists

**Symptom:**
```
Error: A resource with the ID "/subscriptions/.../resourceGroups/rg-myapp-dev-eastus2" already exists
```

**Cause:** A resource group with this name already exists in your subscription

**Solution:**
```bash
# Option 1: Choose a different name
# Edit main.tf and change the name to something unique:
# name = "rg-myapp-dev-eastus2-v2"

# Option 2: Import the existing resource group into Terraform
terraform import azurerm_resource_group.example /subscriptions/YOUR-SUB-ID/resourceGroups/rg-myapp-dev-eastus2

# Then run terraform plan to see if there are any differences
terraform plan
```

### Common Error: Invalid Location

**Symptom:**
```
Error: creating Resource Group "rg-myapp-dev-eastus2": resources.GroupsClient#CreateOrUpdate:
Failure responding to request: StatusCode=400 -- Original Error: autorest/azure: error response cannot be parsed:
"" error: invalid character '<' looking for beginning of value
```

**Cause:** The location name is invalid or not available

**Solution:**
```bash
# List all available locations
az account list-locations --output table

# Common valid locations:
# - eastus, eastus2, westus, westus2, westus3
# - centralus, northcentralus, southcentralus
# - northeurope, westeurope
# - uksouth, ukwest
# - australiaeast, australiasoutheast
# - japaneast, japanwest

# Update main.tf with a valid location
```

### Troubleshooting Authentication

**Problem:** CLI authentication fails

**Solution:**
```bash
# Clear cached credentials
az account clear

# Re-login
az login

# If browser doesn't open automatically, use device code flow
az login --use-device-code

# List subscriptions to verify
az account list --output table

# Set the correct subscription
az account set --subscription "YOUR-SUBSCRIPTION-NAME"
```

### Troubleshooting Terraform Init

**Problem:** Provider download fails

**Solution:**
```bash
# Clear Terraform cache
rm -rf .terraform

# Clear lock file
rm -f .terraform.lock.hcl

# Retry initialization
terraform init

# If still failing, try with plugin cache directory
mkdir -p $HOME/.terraform.d/plugin-cache
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"
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
   - Navigate to: Home > Monitor > Activity Log
   - Filter by: Your resource group name

4. **Ask for help:**
   - Include the error message (remove sensitive data)
   - Include Terraform version: `terraform version`
   - Include Azure CLI version: `az version`
   - Include the resource group name you're trying to create

## Cleanup

**⚠️ IMPORTANT:** Resource groups are free, but it's good practice to clean up when done learning.

### Destroy the Resource Group

```bash
# Show what will be deleted
terraform plan -destroy

# Delete the resource group
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
azurerm_resource_group.example: Destroying... [id=/subscriptions/.../resourceGroups/rg-myapp-dev-eastus2]
azurerm_resource_group.example: Destruction complete after 45s

Destroy complete! Resources: 1 destroyed.
```

### Verify Cleanup

**Check via CLI:**
```bash
# Try to show the resource group (should fail)
az group show --name rg-myapp-dev-eastus2
```

**Expected:**
```
ResourceGroupNotFound: Resource group 'rg-myapp-dev-eastus2' could not be found.
```

**Check via Portal:**
- Go to Azure Portal > Resource groups
- Verify the resource group is deleted

### Clean Up Local Files (Optional)

```bash
# Remove Terraform state files
rm -rf .terraform
rm terraform.tfstate*
rm .terraform.lock.hcl

# Remove configuration files (if you're done)
cd ..
rm -rf azure-resource-group
```

## Cost Breakdown

### Expected Costs

**Resource Groups are completely free:**

| Resource | Tier | Cost/Month |
|----------|------|------------|
| Resource Group | N/A | $0.00 |
| **Total** | | **$0.00** |

**Important notes:**
- Resource groups themselves have no cost
- You only pay for resources you deploy inside them
- There are no limits on the number of resource groups you can create

### Saving Money

💡 **Cost optimization tips:**
- Resource groups are free - no cleanup needed for cost reasons
- Always clean up resources INSIDE the resource group when done testing
- Use tags to track which resources are for learning vs production
- Set up Azure Cost Management alerts to monitor spending

## Next Steps

Now that you've successfully deployed your first resource group, you might want to:

**Related Guides:**
- [How to Deploy Azure Storage Account](../week1-4/howto-deploy-azure-storage.md) - Deploy your first billable resource
- [How to Deploy Azure Virtual Network](../week1-4/howto-deploy-azure-vnet.md) - Create networking infrastructure
- [How to Deploy Web App with Database](../month1-2/howto-deploy-webapp-database.md) - Multi-resource deployment

**Learn More:**
- [Understanding the Terraform Workflow](../week1-4/concept-terraform-workflow.md) - Deep dive into plan/apply/destroy
- [Azure Resource Organization Best Practices](../week1-4/reference-azure-naming-conventions.md) - Naming and tagging standards
- [Terraform State Management](../month1-2/concept-terraform-state.md) - Understanding state files

## Reference

### Complete Terraform Configuration

Full `main.tf` for copy-paste:

```hcl
# Configure the Azure Provider
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Create a Resource Group
resource "azurerm_resource_group" "example" {
  name     = "rg-myapp-dev-eastus2"
  location = "eastus2"

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
    Purpose     = "Learning IaC"
    Owner       = "your-name"
  }
}
```

Full `outputs.tf` for copy-paste:

```hcl
# Outputs to display after deployment
output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.example.name
}

output "resource_group_location" {
  description = "The location of the resource group"
  value       = azurerm_resource_group.example.location
}

output "resource_group_id" {
  description = "The ID of the resource group"
  value       = azurerm_resource_group.example.id
}
```

### Useful Commands

```bash
# View current state
terraform show

# List resources in state
terraform state list

# Get output values
terraform output

# Get specific output value
terraform output resource_group_name

# Format code
terraform fmt

# Validate configuration
terraform validate

# Refresh state from Azure
terraform refresh

# Show state in JSON format
terraform show -json
```

### External Resources

**Official Documentation:**
- [Azure Resource Groups Overview](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/overview#resource-groups)
- [Terraform Azure Provider - Resource Group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group)

**Community Resources:**
- [Terraform Registry - Azure Examples](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Naming Conventions](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
- [Azure Tagging Strategy](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-tagging)

## Glossary Terms Used

All terms below are defined in the [Glossary](../../config/glossary.yaml):

- **Terraform**: Open-source Infrastructure as Code tool for building, changing, and versioning infrastructure
- **Azure**: Microsoft's cloud computing platform
- **Resource Group**: Logical container for Azure resources that share the same lifecycle
- **IaC (Infrastructure as Code)**: The practice of managing infrastructure through code files instead of manual processes

---

**Document Metadata**:
- **Last Updated**: 2025-12-29
- **Tested On**: Terraform v1.9.0, Azure CLI 2.56.0
- **Next Review**: 2026-03-29
- **Maintainer**: IaC Documentation Team
