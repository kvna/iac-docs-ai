---
document_id: howto-terraform-state-management
document_type: howto
skill_level: week1-4
topics: [terraform, state, backend, collaboration, git]
technologies: [terraform_v1.5+, azure_storage, git]
search_keywords:
  - "terraform state"
  - "remote state"
  - "state management"
  - "terraform backend"
  - "state lock"
  - "collaborative terraform"
estimated_time: 30
last_reviewed: 2025-12-28
review_status: current
prerequisites:
  - howto-environment-setup
  - concept-iac-overview
learning_outcomes:
  - Understand what Terraform state is and why it matters
  - Configure remote state storage in Azure
  - Prevent state corruption with state locking
  - Safely collaborate on Terraform code
related_documents:
  - troubleshooting-common-errors
  - reference-naming-conventions
---

# How to Manage Terraform State for Team Collaboration

## Overview

**Goal**: Configure Terraform to safely manage state in a team environment using Azure Storage as a remote backend.

**Why this matters**:
- Prevents multiple people from modifying infrastructure simultaneously
- Enables team collaboration on the same Terraform code
- Protects against state file corruption
- Provides disaster recovery for your infrastructure state

**Prerequisites**:
- ✓ Azure subscription with Contributor access
- ✓ Terraform installed (v1.5+)
- ✓ Azure CLI authenticated
- ✓ Basic understanding of Terraform (see concept-iac-overview)

## What is Terraform State?

Terraform state (`terraform.tfstate`) is a JSON file that:
- Maps your Terraform code to real Azure resources
- Tracks resource metadata and dependencies
- Enables Terraform to determine what changes are needed

**Example state snippet:**
```json
{
  "resources": [
    {
      "type": "azurerm_resource_group",
      "name": "main",
      "instances": [
        {
          "attributes": {
            "id": "/subscriptions/.../resourceGroups/rg-myapp-prod",
            "location": "northeurope",
            "name": "rg-myapp-prod"
          }
        }
      ]
    }
  ]
}
```

**The problem with local state**:
- ❌ Only one person can work at a time
- ❌ State file can be lost if computer fails
- ❌ Hard to share with team
- ❌ No locking mechanism
- ❌ Sensitive data stored in plain text

**The solution: Remote state**
- ✅ Stored in Azure Blob Storage
- ✅ Automatic state locking
- ✅ Encrypted at rest and in transit
- ✅ Team can collaborate safely
- ✅ Versioned and backed up

## Step 1: Create State Storage Account

First, create an Azure Storage Account to hold your Terraform state.

```bash
# Set variables
RESOURCE_GROUP="rg-terraform-state"
STORAGE_ACCOUNT="sttfstate$(openssl rand -hex 4)"  # Unique name
LOCATION="northeurope"
CONTAINER_NAME="tfstate"

# Create resource group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

# Create storage account
az storage account create \
  --resource-group $RESOURCE_GROUP \
  --name $STORAGE_ACCOUNT \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob \
  --https-only true \
  --min-tls-version TLS1_2

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list \
  --resource-group $RESOURCE_GROUP \
  --account-name $STORAGE_ACCOUNT \
  --query '[0].value' -o tsv)

# Create blob container
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT \
  --account-key $ACCOUNT_KEY

echo "Storage Account: $STORAGE_ACCOUNT"
echo "Resource Group: $RESOURCE_GROUP"
echo "Container: $CONTAINER_NAME"
```

**Security best practices**:
- ✅ Use a dedicated resource group for state storage
- ✅ Enable versioning for disaster recovery
- ✅ Restrict access with RBAC (not included in script above)
- ✅ Consider using Managed Identity instead of access keys

## Step 2: Configure Backend in Terraform

Add a backend configuration to your Terraform code.

**File: `terraform/environments/prod/backend.tf`**
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstateXXXXXXXX"  # Replace with your storage account name
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"  # Unique per environment
  }
}
```

**Alternatively, use a backend config file** (recommended for multiple environments):

**File: `terraform/environments/prod/backend.hcl`**
```hcl
resource_group_name  = "rg-terraform-state"
storage_account_name = "sttfstateXXXXXXXX"
container_name       = "tfstate"
key                  = "prod.terraform.tfstate"
```

Then initialize with:
```bash
terraform init -backend-config=backend.hcl
```

## Step 3: Migrate Existing State

If you already have local state, migrate it to the remote backend.

```bash
# Navigate to your Terraform directory
cd terraform/environments/prod

# Initialize with backend configuration
terraform init -backend-config=backend.hcl

# Terraform will detect existing local state and prompt:
# "Do you want to copy existing state to the new backend?"
# Answer: yes

# Verify migration
terraform state list

# Your state is now in Azure!
# You can safely delete the local terraform.tfstate file
# (But keep a backup copy first, just in case)
```

## Step 4: Enable State Locking

State locking prevents concurrent modifications. The Azure backend automatically uses state locking via blob leases.

**How it works**:
1. When you run `terraform apply`, Azure acquires a lease on the state blob
2. Other users trying to run Terraform get a lock error
3. When your operation completes, the lease is released

**Test state locking**:

Terminal 1:
```bash
terraform plan
# Leave this running (use -lock-timeout=10m for long operations)
```

Terminal 2:
```bash
terraform plan
# You'll get an error:
# Error: Error acquiring the state lock
# Lock Info:
#   ID:        abc-123-def
#   Who:       john.doe@laptop
```

## Step 5: Team Collaboration Workflow

Now your team can safely collaborate:

**Developer A** (working on Feature X):
```bash
git pull origin main
cd terraform/environments/dev
terraform init
terraform plan    # Reviews planned changes
terraform apply   # State is locked during apply
git add .
git commit -m "Add new storage account"
git push origin feature/storage-account
```

**Developer B** (working on Feature Y):
```bash
git pull origin main
cd terraform/environments/dev
terraform init
terraform plan    # Will wait if Developer A's apply is running
terraform apply
git add .
git commit -m "Add new key vault"
git push origin feature/key-vault
```

**Important**:
- ✅ Always `git pull` before making changes
- ✅ Always run `terraform plan` before `terraform apply`
- ✅ Coordinate large changes with team
- ✅ Use feature branches for experimentation
- ❌ Never commit `terraform.tfstate` to Git (it's in Azure now!)

## Step 6: State File Organization

Organize state files by environment:

```
Azure Blob Storage: tfstate container
├── dev.terraform.tfstate         # Development environment
├── test.terraform.tfstate        # Testing environment
├── stage.terraform.tfstate       # Staging environment
└── prod.terraform.tfstate        # Production environment
```

Each environment gets its own state file:

**Dev environment**:
```hcl
# terraform/environments/dev/backend.hcl
key = "dev.terraform.tfstate"
```

**Prod environment**:
```hcl
# terraform/environments/prod/backend.hcl
key = "prod.terraform.tfstate"
```

This isolates environments and prevents accidental cross-environment changes.

## Disaster Recovery

### Backup Strategy

Azure Storage automatically provides:
- ✅ Geo-redundant storage (configure with `--sku Standard_GRS`)
- ✅ Soft delete (recoverable for 14 days)
- ✅ Versioning (access previous state versions)

**Enable versioning**:
```bash
az storage account blob-service-properties update \
  --resource-group $RESOURCE_GROUP \
  --account-name $STORAGE_ACCOUNT \
  --enable-versioning true
```

**Enable soft delete**:
```bash
az storage account blob-service-properties update \
  --resource-group $RESOURCE_GROUP \
  --account-name $STORAGE_ACCOUNT \
  --enable-delete-retention true \
  --delete-retention-days 14
```

### Restore from Backup

If state becomes corrupted:

```bash
# List blob versions
az storage blob list \
  --container-name tfstate \
  --account-name $STORAGE_ACCOUNT \
  --include v \
  --query "[?name=='prod.terraform.tfstate'].{Name:name, Version:versionId, Time:properties.creationTime}"

# Download a specific version
az storage blob download \
  --container-name tfstate \
  --name prod.terraform.tfstate \
  --version-id "2024-01-15T10:30:00.0000000Z" \
  --file ./terraform.tfstate.backup \
  --account-name $STORAGE_ACCOUNT

# Restore by uploading
az storage blob upload \
  --container-name tfstate \
  --name prod.terraform.tfstate \
  --file ./terraform.tfstate.backup \
  --account-name $STORAGE_ACCOUNT \
  --overwrite
```

## Security Considerations

### Access Control

Limit who can access the state storage account:

```bash
# Grant read/write access to infrastructure team
az role assignment create \
  --assignee group-infra-team@company.com \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/xxx/resourceGroups/rg-terraform-state/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT"

# Grant read-only access to developers
az role assignment create \
  --assignee group-developers@company.com \
  --role "Storage Blob Data Reader" \
  --scope "/subscriptions/xxx/resourceGroups/rg-terraform-state/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT"
```

### Encrypt Sensitive Data

State files contain sensitive information (passwords, keys, connection strings).

**Best practices**:
- ✅ Enable encryption at rest (enabled by default in Azure Storage)
- ✅ Use HTTPS only (enforced in our setup)
- ✅ Use Azure RBAC instead of storage account keys
- ✅ Consider using Managed Identity for authentication
- ⚠️ Never commit state files to Git
- ⚠️ Limit access to state storage account

## Common Issues

### Issue: Lock Timeout

**Error**: `Error: Error acquiring the state lock`

**Cause**: Someone else is running Terraform, or a previous run didn't release the lock.

**Solution**: See troubleshooting-common-errors#state-lock-conflicts

### Issue: State Drift

**Error**: `terraform plan` shows unexpected changes

**Cause**: Resources were modified outside of Terraform.

**Solution**:
```bash
# Refresh state from Azure
terraform apply -refresh-only

# Review differences
terraform plan
```

### Issue: Cannot Access State

**Error**: `Error: Failed to get existing workspaces: storage: service returned error: StatusCode=403`

**Cause**: Insufficient permissions on storage account.

**Solution**: Verify RBAC permissions or use storage account key.

## Summary

You now have:
- ✅ Remote state in Azure Storage
- ✅ Automatic state locking
- ✅ Team collaboration enabled
- ✅ Disaster recovery with versioning
- ✅ Secure access control

**Key commands**:
```bash
# Initialize backend
terraform init -backend-config=backend.hcl

# Always run before changes
terraform plan

# Safe to run in parallel with team (locking prevents conflicts)
terraform apply

# List all resources in state
terraform state list

# View specific resource
terraform state show azurerm_resource_group.main
```

**Next steps**:
- Set up CI/CD pipeline for automated Terraform runs
- Implement state backup automation
- Configure monitoring/alerts for state changes

---

**Related Documentation**:
- [Troubleshooting: State Lock Conflicts](troubleshooting-common-errors.md#state-lock-conflicts)
- [Reference: Naming Conventions](../reference/reference-naming-conventions.md)
- [Concept: IaC Overview](../day1/concept-iac-overview.md)
