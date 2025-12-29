---
document_id: howto-deploy-[resource-name]
document_type: howto
skill_level: [day1|week1-4|month1-2|month3-6|month6-12]
topics: [deployment, operations, [azure|aws], [resource-type]]
technologies: [terraform_v1.5+, [azure_cli_2.50+|aws_cli_2.x], [platform-specific-tech]]
prerequisites:
  - "Azure/AWS account with appropriate permissions"
  - "Terraform installed (v1.5+)"
  - "Azure CLI/AWS CLI installed and configured"
  - "[Any specific prerequisite knowledge or tools]"
learning_outcomes:
  - Successfully deploy [resource/application] to [Azure/AWS]
  - Verify the deployment is working correctly
  - Understand how to troubleshoot common issues
  - Know how to clean up resources to avoid costs
estimated_time: [minutes]
last_reviewed: YYYY-MM-DD
review_status: current
search_keywords:
  - "how to deploy [resource] to [azure/aws]"
  - "[resource] terraform deployment"
  - "step by step [resource] deployment"
  - "[resource] deployment guide"
related_documents:
  - concept-iac-overview
  - howto-environment-setup
  - [other-related-guides]
glossary_terms:
  - terraform
  - [azure|aws]
  - [resource-specific-terms]
---

# How to Deploy [Resource/Application Name]

## Overview

**Purpose**: Provide step-by-step instructions to deploy [describe what] to [Azure/AWS] using Terraform.

**What You'll Deploy**:
- [Resource 1 description]
- [Resource 2 description]
- [Resource N description]

**Estimated Time**: [X] minutes

**Estimated Cost**:
- Development: $[X]/month
- Production: $[Y]/month
- Can run on free tier: [Yes/No]

## Prerequisites

### Required Tools

Verify you have the following tools installed:

| Tool | Minimum Version | Check Command | Install Guide |
|------|----------------|---------------|---------------|
| Terraform | 1.5+ | `terraform version` | [Link] |
| [Azure CLI / AWS CLI] | [Version] | `az version` / `aws --version` | [Link] |
| [Other tools] | [Version] | [Command] | [Link] |

### Required Access

- [ ] [Azure/AWS] account
- [ ] Subscription/Account ID: `_________________`
- [ ] Required permissions: [List specific permissions]
- [ ] Service quotas: [Any quota requirements]

### Required Knowledge

Before starting, you should understand:
- [ ] Basic terminal/command line usage
- [ ] What a [resource-type] is and why you'd use it
- [ ] How to authenticate with [Azure/AWS] CLI

**New to these concepts?** Read [link to concept doc] first.

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
# Check Azure CLI / AWS CLI
az version  # Azure
# OR
aws --version  # AWS
```

**Expected output:**
```
azure-cli 2.50.0 or higher
# OR
aws-cli/2.x.x
```

❌ **If any tool is missing:** Install it following the [Environment Setup Guide](../day1/howto-environment-setup.md)

### Step 2: Authenticate to Cloud Provider

**For Azure:**
```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "YOUR-SUBSCRIPTION-NAME"

# Verify you're logged in
az account show
```

**For AWS:**
```bash
# Configure AWS credentials
aws configure

# Verify credentials
aws sts get-caller-identity
```

**Expected output:**
```json
{
  "UserId": "...",
  "Account": "123456789012",
  "Arn": "arn:aws:iam::..."
}
```

❌ **If authentication fails:** Check [Troubleshooting Authentication](#troubleshooting-authentication)

### Step 3: Create Working Directory

```bash
# Create project directory
mkdir -p ~/terraform-projects/[project-name]
cd ~/terraform-projects/[project-name]

# Verify you're in the right place
pwd
```

**Expected output:**
```
/home/[your-username]/terraform-projects/[project-name]
```

## Deployment Steps

### Step 1: Create Terraform Configuration

Create a file named `main.tf`:

```bash
# Create the file
cat > main.tf << 'EOF'
[Complete Terraform configuration here]
EOF
```

**What this does:**
- [Explain what the configuration does]
- [Explain key resources]
- [Explain important settings]

### Step 2: Create Variables File (Optional)

If you need to customize values, create `terraform.tfvars`:

```bash
cat > terraform.tfvars << 'EOF'
[Variables configuration]
EOF
```

**Customize these values:**
- `[variable_name]` = [Description of what to change]

### Step 3: Initialize Terraform

```bash
terraform init
```

**What this does:**
- Downloads required provider plugins
- Initializes the backend
- Prepares your working directory

**Expected output:**
```
Initializing the backend...
Initializing provider plugins...
- Finding latest version of [provider]...
- Installing [provider] v[version]...

Terraform has been successfully initialized!
```

❌ **If initialization fails:** Check [Troubleshooting Terraform Init](#troubleshooting-terraform-init)

### Step 4: Review the Deployment Plan

```bash
terraform plan
```

**What this does:**
- Shows what Terraform will create/change
- Validates your configuration
- Checks for errors before deploying

**Expected output:**
```
Terraform will perform the following actions:

  # [resource_type].[resource_name] will be created
  + resource "[resource_type]" "[resource_name]" {
      + [attribute] = [value]
    }

Plan: X to add, 0 to change, 0 to destroy.
```

**Review the plan carefully:**
- [ ] Resources being created match what you expect
- [ ] No unexpected changes or deletions
- [ ] Resource names follow your naming conventions

### Step 5: Deploy the Resources

```bash
terraform apply
```

**What this does:**
- Creates the resources in [Azure/AWS]
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
[resource_type].[resource_name]: Creating...
[resource_type].[resource_name]: Creation complete after Xs

Apply complete! Resources: X added, 0 changed, 0 destroyed.

Outputs:

[output_name] = "[output_value]"
```

**⏱️ Deployment time:** Typically takes [X-Y] minutes.

### Step 6: Save Important Values

Copy these values for later use:

```bash
# Display all outputs
terraform output
```

**Save these values:**
```
[output_name_1] = [description]
[output_name_2] = [description]
```

## Verification

### Verify Deployment via CLI

**Check resource exists:**
```bash
# Azure
az [resource-type] show --name [resource-name] --resource-group [rg-name]

# AWS
aws [service] describe-[resource] --[resource]-id [id]
```

**Expected output:**
```json
{
  "id": "[resource-id]",
  "name": "[resource-name]",
  "provisioningState": "Succeeded",
  ...
}
```

### Verify via Portal

1. **Azure Portal**: https://portal.azure.com
   - Navigate to: [Navigation path]
   - You should see: [What to look for]

2. **AWS Console**: https://console.aws.amazon.com
   - Navigate to: [Service] > [Section]
   - You should see: [What to look for]

### Test the Deployment

Run this test to confirm everything works:

```bash
[Test command]
```

**Expected result:**
```
[Expected output]
```

✅ **Success indicators:**
- [ ] [Indicator 1]
- [ ] [Indicator 2]
- [ ] [Indicator 3]

## Troubleshooting

### Common Error: [Error Name]

**Symptom:**
```
Error: [Error message]
```

**Cause:** [Explanation of what causes this]

**Solution:**
```bash
# Step 1: [What to do]
[command]

# Step 2: [What to do next]
[command]

# Step 3: Retry deployment
terraform apply
```

### Common Error: [Another Error]

**Symptom:**
```
Error: [Error message]
```

**Cause:** [Explanation]

**Solution:**
[Steps to fix]

### Troubleshooting Authentication

**Problem:** CLI authentication fails

**Azure:**
```bash
# Clear cached credentials
az account clear

# Re-login
az login

# List subscriptions
az account list --output table
```

**AWS:**
```bash
# Verify credentials file
cat ~/.aws/credentials

# Test authentication
aws sts get-caller-identity
```

### Troubleshooting Terraform Init

**Problem:** Provider download fails

**Solution:**
```bash
# Clear Terraform cache
rm -rf .terraform

# Clear lock file
rm .terraform.lock.hcl

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

3. **Check cloud provider logs:**
   - Azure: Activity Log in Portal
   - AWS: CloudTrail in Console

4. **Ask for help:**
   - Include error message
   - Include Terraform version
   - Include relevant configuration (remove sensitive data)

## Cleanup

**⚠️ IMPORTANT:** Running resources incur costs. Clean up when done testing.

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
[resource_type].[resource_name]: Destroying...
[resource_type].[resource_name]: Destruction complete after Xs

Destroy complete! Resources: X destroyed.
```

### Verify Cleanup

**Check via CLI:**
```bash
# Azure
az [resource-type] list --resource-group [rg-name]

# AWS
aws [service] describe-[resources]
```

**Expected:** Should return empty or not found.

**Check via Portal:**
- Verify resources are deleted
- Check for any orphaned resources

### Clean Up Local Files (Optional)

```bash
# Remove Terraform state files
rm -rf .terraform
rm terraform.tfstate*
rm .terraform.lock.hcl

# Remove configuration files (if you're done)
cd ..
rm -rf [project-name]
```

## Cost Breakdown

### Expected Costs

**If you run this 24/7:**

| Resource | Tier | Cost/Month |
|----------|------|------------|
| [Resource 1] | [Tier] | $[amount] |
| [Resource 2] | [Tier] | $[amount] |
| **Total** | | **$[total]** |

**If you only run during business hours (8hrs/day, 5days/week):**
- Approximate: $[amount]/month

**Free tier eligible:**
- [Yes/No + details]

### Saving Money

💡 **Cost optimization tips:**
- Destroy resources when not in use
- Use smaller instance sizes for development
- Consider reserved instances for production
- Set up budget alerts

## Next Steps

Now that you've successfully deployed [resource], you might want to:

**Related Guides:**
- [Next logical step guide]
- [Advanced configuration guide]
- [Integration guide]

**Learn More:**
- [Concept document]
- [Reference documentation]
- [Best practices guide]

## Reference

### Complete Terraform Configuration

Full `main.tf` for copy-paste:

```hcl
[Complete configuration]
```

### Useful Commands

```bash
# View current state
terraform show

# List resources
terraform state list

# Get output values
terraform output

# Format code
terraform fmt

# Validate configuration
terraform validate

# Refresh state
terraform refresh
```

### External Resources

**Official Documentation:**
- [Azure/AWS Resource Documentation]
- [Terraform Provider Documentation]

**Community Resources:**
- [Terraform Registry Examples]
- [Cloud Provider Tutorials]

## Glossary Terms Used

All terms below are defined in the [Glossary](../../config/glossary.yaml):

- **[Term 1]**: [Brief definition]
- **[Term 2]**: [Brief definition]
- **[Term N]**: [Brief definition]

---

**Document Metadata**:
- **Last Updated**: YYYY-MM-DD
- **Tested On**: [Terraform version], [CLI version]
- **Next Review**: YYYY-MM-DD
- **Maintainer**: [Team/Person]
