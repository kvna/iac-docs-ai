---
document_id: troubleshooting-common-errors
document_type: troubleshooting
skill_level: day1
topics: [errors, debugging, troubleshooting, common-issues]
technologies: [terraform, azure_cli, powershell]
search_keywords:
  - "terraform error"
  - "common errors"
  - "troubleshooting guide"
  - "fix deployment errors"
  - "azure terraform problems"
estimated_time: 20
last_reviewed: 2025-12-28
review_status: current
related_documents:
  - howto-environment-setup
  - concept-terraform-workflow
---

# Troubleshooting Common Terraform and Azure Errors

## Overview

**Purpose**: Identify and resolve the most common errors encountered when working with Terraform and Azure.

**Use this guide when**:
- Your Terraform deployment fails
- You encounter authentication errors
- Resources fail to create
- You see cryptic error messages

## Common Error Patterns

### 1. Authentication Errors

**Error Message:**
```
Error: building AzureRM Client: obtain subscription() from Azure CLI...
AADSTS50058: A silent sign-in request was sent but no user is signed in.
```

**Cause**: Not logged in to Azure CLI or session expired.

**Solution**:
```bash
# Login to Azure
az login

# Verify you're logged in
az account show

# Set the correct subscription if you have multiple
az account set --subscription "your-subscription-name"
```

**Prevention**: Run `az account show` before starting work to verify authentication.

---

### 2. Provider Version Mismatch

**Error Message:**
```
Error: Failed to query available provider packages
Could not retrieve the list of available versions for provider hashicorp/azurerm
```

**Cause**: Terraform can't download or find the Azure provider.

**Solution**:
```bash
# Re-initialize Terraform
terraform init -upgrade

# If behind a proxy, configure:
export HTTPS_PROXY=http://proxy.company.com:8080
terraform init
```

**Prevention**: Run `terraform init` whenever you pull changes that modify provider versions.

---

### 3. State Lock Conflicts

**Error Message:**
```
Error: Error acquiring the state lock
Lock Info:
  ID:        abc-123-def
  Path:      terraform.tfstate
  Operation: OperationTypePlan
  Who:       john.doe@laptop
```

**Cause**: Another Terraform process is running, or a previous run didn't release the lock.

**Solution**:
```bash
# Check who has the lock (shown in error message)
# If it's you and the process crashed:
terraform force-unlock abc-123-def

# If it's someone else, coordinate with them first!
```

**Prevention**:
- Always wait for Terraform operations to complete
- Use `-lock-timeout=10m` for long-running operations
- Coordinate with team members

---

### 4. Resource Already Exists

**Error Message:**
```
Error: A resource with the ID "/subscriptions/.../resourceGroups/rg-myapp-prod" already exists

To be managed via Terraform this resource needs to be imported into the State.
```

**Cause**: Resource exists in Azure but not in Terraform state.

**Solution**:
```bash
# Import the existing resource
terraform import azurerm_resource_group.main /subscriptions/xxx/resourceGroups/rg-myapp-prod

# Or, if you want to start fresh:
# 1. Manually delete the resource in Azure Portal
# 2. Re-run terraform apply
```

**Prevention**: Always check Azure Portal before creating resources with terraform apply.

---

### 5. Quota/Limit Exceeded

**Error Message:**
```
Error: creating Cognitive Services Account:
Code="QuotaExceeded"
Message="You have exceeded your quota for OpenAI resources in this region"
```

**Cause**: Subscription has reached Azure quota limits.

**Solution**:
```bash
# Check current quotas
az vm list-usage --location northeurope -o table

# Request quota increase
# Azure Portal → Subscriptions → Usage + quotas → Request increase
```

**Workaround**: Deploy to a different region or use a different subscription.

**Prevention**: Check quotas before large deployments.

---

### 6. Invalid Resource Name

**Error Message:**
```
Error: creating Storage Account:
storage account name must be between 3 and 24 characters in length
and use numbers and lower-case letters only
```

**Cause**: Resource name doesn't meet Azure naming requirements.

**Solution**:
```hcl
# Fix the name in your Terraform code
resource "azurerm_storage_account" "main" {
  name = "stmyappprod001"  # No hyphens, lowercase only
  # ...
}
```

**Prevention**: Follow the naming conventions guide (reference-naming-conventions).

---

### 7. Missing Required Permissions

**Error Message:**
```
Error: authorization failed for this request
Status Code: 403
Error: Insufficient privileges to complete the operation
```

**Cause**: Your Azure AD account lacks necessary RBAC permissions.

**Solution**:
```bash
# Check your current role assignments
az role assignment list --assignee your.email@company.com

# You need at least "Contributor" role on the resource group
# Contact your Azure administrator to grant permissions
```

**Prevention**: Verify permissions before starting work, especially in shared subscriptions.

---

### 8. Terraform Plan Shows Unexpected Changes

**Error Message:** (Not an error, but unexpected behavior)
```
Terraform will perform the following actions:
  # azurerm_resource_group.main will be replaced
  -/+ resource "azurerm_resource_group" "main" {
```

**Cause**: State drift - resources were modified outside of Terraform.

**Solution**:
```bash
# Refresh state to see current Azure state
terraform refresh

# Review what changed
terraform plan

# To accept Azure changes and update state:
terraform apply -refresh-only

# To force Terraform's version:
terraform apply
```

**Prevention**:
- Never modify resources in Azure Portal if managed by Terraform
- Use `terraform apply -refresh-only` regularly to detect drift

---

### 9. Terraform Destroy Stuck

**Error Message:**
```
Error: deleting Resource Group:
Code="ResourceGroupBeingDeleted"
Message="The resource group is being deleted. Please retry later."
```

**Cause**: Azure is still deleting resources (can take 10-15 minutes for Key Vault).

**Solution**:
```bash
# Wait patiently. Key Vault has soft-delete protection.
# Check status:
az group show --name rg-myapp-prod

# If truly stuck after 30 minutes:
az group delete --name rg-myapp-prod --yes --no-wait
```

**Prevention**: Expect delays when deleting Key Vaults. Plan accordingly.

---

### 10. Module Source Not Found

**Error Message:**
```
Error: Failed to download module
Could not download module "network" (main.tf:10) source code from "../../modules/network"
```

**Cause**: Incorrect relative path to module.

**Solution**:
```hcl
# Fix the path in your module block
module "network" {
  source = "../../modules/network"  # Verify this path is correct
  # ...
}

# Re-initialize
terraform init
```

**Prevention**: Use absolute paths or verified relative paths. Test with `ls ../../modules/network`.

---

## Debugging Workflow

When you encounter an error:

1. **Read the Error Message Carefully**
   - Look for error codes (e.g., `QuotaExceeded`, `AADSTS50058`)
   - Note the resource type and operation

2. **Check Prerequisites**
   ```bash
   az account show      # Am I logged in?
   az --version         # Is Azure CLI up to date?
   terraform version    # Is Terraform up to date?
   ```

3. **Enable Debug Logging**
   ```bash
   export TF_LOG=DEBUG
   export TF_LOG_PATH=./terraform-debug.log
   terraform apply
   ```

4. **Search for the Error**
   - Check this troubleshooting guide
   - Search the error message in team documentation
   - Check Azure documentation
   - Search Stack Overflow

5. **Isolate the Problem**
   ```bash
   # Test one resource at a time
   terraform plan -target=azurerm_resource_group.main

   # Validate syntax
   terraform validate

   # Format check
   terraform fmt -check
   ```

6. **Ask for Help**
   - Include the full error message
   - Include relevant Terraform code
   - Include what you've tried
   - Post in team chat or documentation gap report

## Getting Help

**Internal Resources**:
- Team Wiki: [link to wiki]
- Team Chat: #infrastructure-help
- Office Hours: Fridays 2-3pm

**External Resources**:
- [Terraform Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure CLI Reference](https://learn.microsoft.com/cli/azure/)
- [Terraform Troubleshooting](https://developer.hashicorp.com/terraform/tutorials/configuration-language/troubleshooting-workflow)

## Prevention Checklist

Before running Terraform:
- [ ] Logged in to Azure (`az account show`)
- [ ] Correct subscription selected
- [ ] Latest code pulled from Git
- [ ] Terraform initialized (`terraform init`)
- [ ] Validated syntax (`terraform validate`)
- [ ] Reviewed plan (`terraform plan`)
- [ ] Checked for state locks
- [ ] Verified permissions

After successful deployment:
- [ ] Resources created as expected
- [ ] Committed state changes to Git (if using remote state)
- [ ] Updated documentation if needed
- [ ] Informed team of changes

## Summary

Most errors fall into these categories:
1. **Authentication** → Run `az login`
2. **Permissions** → Request RBAC access
3. **Naming** → Follow naming conventions
4. **Quotas** → Request increase or change region
5. **State conflicts** → Coordinate with team

**Remember**: Error messages are helpful! Read them carefully and follow the suggested actions.

---

**Related Documents**:
- [How-To: Environment Setup](howto-environment-setup.md)
- [Reference: Naming Conventions](../reference/reference-naming-conventions.md)
- [Concept: Terraform Workflow](concept-terraform-workflow.md) (if created)
