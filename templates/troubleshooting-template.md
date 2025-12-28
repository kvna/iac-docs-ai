---
document_id: troubleshooting-[short-descriptive-id]
document_type: troubleshooting
skill_level: [day1|week1-4|month1-2|month3-6|month6-12|expert]
topics: [list, of, topics]
technologies: [terraform_v1.5+, azure_cli_2.50+, powershell_7.4+, azuredevops]
prerequisites:
  - [document_id_of_prerequisite_1]
learning_outcomes:
  - [How to diagnose specific problem]
  - [How to resolve specific issue]
estimated_time: [varies by issue]
last_reviewed: [YYYY-MM-DD]
review_status: [current|needs_review|deprecated]
search_keywords:
  - "[error message exact text]"
  - "[problem symptom]"
  - "[how to fix X]"
  - "[X not working]"
  - "[troubleshoot X]"
related_documents:
  - [related_document_id_1]
  - [related_document_id_2]
glossary_terms:
  - [term_from_glossary]
common_errors:
  - "[exact error message 1]"
  - "[exact error message 2]"
---

# Troubleshooting: [Problem Area]

## Overview

This guide helps you diagnose and resolve common issues related to [problem area]. Use this guide when you encounter [types of symptoms or errors].

**Common Symptoms**:
- [Symptom 1]
- [Symptom 2]
- [Symptom 3]

**Coverage**: This guide addresses issues at the [skill level] and assumes you have completed [prerequisite knowledge].

---

## Quick Diagnostic Checklist

Before diving into specific issues, check these common causes:

- [ ] **Authentication**: Are you logged in? Run `az account show` to verify
- [ ] **Permissions**: Do you have required permissions? Check RBAC assignments
- [ ] **Versions**: Are your tools up to date? Check Terraform, Azure CLI versions
- [ ] **Connectivity**: Can you reach Azure? Test with `az account list`
- [ ] **State**: Is your state file accessible and not locked? Check backend storage
- [ ] **Syntax**: Are there any typo or syntax errors? Run validation commands

**Still having issues?** Proceed to specific problem sections below.

---

## Problem Index

Quick links to specific issues:

1. [Error: [Specific Error Name]](#error-specific-error-name)
2. [Problem: [Symptom Description]](#problem-symptom-description)
3. [Issue: [Behavior Description]](#issue-behavior-description)

---

## Error: [Specific Error Message or Code]

### Symptom

**Error Message**:
```
[Exact error message as it appears]
Error: [error code/description]
[Full stack trace if relevant]
```

**When It Occurs**:
- During [specific operation]
- After [specific action]
- When [specific condition]

**Affected Components**:
- [Component 1]
- [Component 2]

### Cause

**Root Cause**: [Explain why this error occurs]

**Contributing Factors**:
1. [Factor 1]
2. [Factor 2]
3. [Factor 3]

**Technical Details**: [Deeper explanation for advanced users]

### Diagnosis

**Step 1: Verify the Error**

Confirm you're experiencing this specific issue:

```bash
# Run diagnostic command
[command to reproduce or verify the error]
```

**Expected symptoms if this is your issue**:
- [Symptom A]
- [Symptom B]

**Step 2: Check Related Components**

```bash
# Check component status
[verification command]

# Look for these indicators:
# - [Indicator 1]
# - [Indicator 2]
```

**Step 3: Review Configuration**

Check your configuration file for:
- [ ] [Configuration point 1]
- [ ] [Configuration point 2]
- [ ] [Configuration point 3]

### Solution

#### Option 1: [Primary/Recommended Solution]

**When to use**: [Conditions where this solution applies]

**Risk Level**: Low/Medium/High
**Time Required**: [X] minutes

**Steps**:

1. **[First action]**:
   ```bash
   [command or configuration change]
   ```

   **Why**: [Explanation of what this does]

2. **[Second action]**:
   ```bash
   [command]
   ```

   **Expected output**:
   ```
   [What you should see]
   ```

3. **[Third action]**:
   ```bash
   [command]
   ```

4. **Verify the fix**:
   ```bash
   [verification command]
   ```

   **Success indicators**:
   - [How you know it worked]
   - [What changed]

#### Option 2: [Alternative Solution]

**When to use**: [Different conditions or if Option 1 doesn't work]

**Risk Level**: Low/Medium/High
**Time Required**: [X] minutes

**Steps**:

[Follow same structure as Option 1]

#### Option 3: [Advanced/Last Resort Solution]

**When to use**: [When other options fail or specific conditions]

**Risk Level**: Medium/High
**Time Required**: [X] minutes
**Warning**: [Any risks or considerations]

**Steps**:

[Follow same structure as Option 1]

### Prevention

**How to avoid this in the future**:

1. **Preventive Measure 1**:
   - [Action to take]
   - [Why this helps]

2. **Preventive Measure 2**:
   - [Action to take]
   - [Automation opportunity]

3. **Best Practice**:
   - [Long-term solution]
   - [Process change]

**Recommended Configuration**:
```hcl
# Configuration that prevents this issue
[code example]
```

### Related Issues

This error is sometimes confused with or related to:
- [Related Issue 1]: [How to distinguish]
- [Related Issue 2]: [Connection]

---

## Problem: [Symptom-Based Issue]

### Symptom

**What You're Experiencing**:
- [Behavior you're seeing]
- [What's not working as expected]
- [Specific outcome that's wrong]

**Impact**:
- [How this affects your work]
- [Severity level]

### Possible Causes

This problem can result from multiple causes. Work through these in order:

#### Cause 1: [Most Common Cause]

**Likelihood**: High/Medium/Low
**How to check**:
```bash
[diagnostic command]
```

**If this is the cause, you'll see**:
- [Indicator 1]
- [Indicator 2]

**Solution**: [Link to solution section below or steps]

---

#### Cause 2: [Second Common Cause]

**Likelihood**: High/Medium/Low
**How to check**:
```bash
[diagnostic command]
```

**Indicators**:
- [What indicates this cause]

**Solution**: [Link or steps]

---

#### Cause 3: [Less Common Cause]

**Likelihood**: Low
**How to check**:
[Steps to verify]

**Solution**: [Link or steps]

### Diagnosis Flow

```
Start Here
    │
    ▼
Check [First thing]? ──Yes──▶ [Solution A]
    │
   No
    │
    ▼
Check [Second thing]? ──Yes──▶ [Solution B]
    │
   No
    │
    ▼
Check [Third thing]? ──Yes──▶ [Solution C]
    │
   No
    │
    ▼
See [Advanced Troubleshooting]
```

### Solution for Cause 1

[Detailed solution steps]

### Solution for Cause 2

[Detailed solution steps]

### Solution for Cause 3

[Detailed solution steps]

---

## Issue: [Configuration or Behavior Issue]

### Description

**What's Happening**:
[Description of the unexpected behavior or configuration issue]

**Expected Behavior**:
[What should be happening instead]

**Gap Analysis**:
[Difference between expected and actual]

### Investigation Steps

**Step 1: Gather Information**

Collect the following details:

```bash
# Get current state
[command to show current config]

# Get version information
[command to show versions]

# Get resource status
[command to check resource]
```

**Save this information** - you may need it for support escalation.

**Step 2: Check Documentation**

Verify your understanding against:
- [Reference doc for correct behavior]
- [Concept doc for how it should work]

**Step 3: Compare Against Working Example**

```hcl
# Working configuration example
[code that works correctly]
```

**Key differences to look for**:
- [Difference 1]
- [Difference 2]

### Resolution

**Corrective Actions**:

1. **Update Configuration**:

   Change this:
   ```hcl
   # Incorrect or problematic configuration
   [before code]
   ```

   To this:
   ```hcl
   # Correct configuration
   [after code]
   ```

   **Why**: [Explanation of why this fixes it]

2. **Apply Changes**:
   ```bash
   terraform plan  # Review changes
   terraform apply # Apply correction
   ```

3. **Validate**:
   ```bash
   [validation command]
   ```

---

## Advanced Troubleshooting

### Enable Verbose Logging

Get more detailed error information:

**Terraform**:
```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform-debug.log
terraform [command]
```

**Azure CLI**:
```bash
az [command] --debug
```

**PowerShell**:
```powershell
$DebugPreference = "Continue"
[command]
```

### Review Logs

**Where to find logs**:
- Terraform: `./terraform-debug.log` or stdout
- Azure Activity Log: Portal > Activity Log
- Azure DevOps: Pipeline run logs
- Local: `~/.azure/*.log`

**What to look for**:
- Error codes
- Failed API calls
- Permission denied messages
- Timeout errors

### State File Issues

**Check state file integrity**:
```bash
terraform state list  # Should list all resources
terraform state show [resource]  # Show resource detail
```

**Common state problems**:

1. **State locked**:
   ```bash
   # Check lock status
   terraform force-unlock [lock-id]
   ```
   ⚠️ **Warning**: Only do this if you're certain no other operations are running

2. **State out of sync**:
   ```bash
   terraform refresh
   terraform state pull > backup.tfstate  # Backup first
   ```

3. **State corruption**:
   - Restore from backend versioning
   - Use backup state file
   - See [State Recovery Guide](link)

### Network Troubleshooting

**Test connectivity**:
```bash
# Test Azure connectivity
az account list

# Test specific endpoint
curl -v https://management.azure.com/

# Check DNS resolution
nslookup management.azure.com
```

**Common network issues**:
- Firewall blocking Azure endpoints
- Proxy configuration problems
- VPN/Network routing issues

### Permission Troubleshooting

**Check your permissions**:
```bash
# See current account
az account show

# List role assignments
az role assignment list --assignee [your-email]

# Check specific resource permissions
az role assignment list --scope /subscriptions/[sub-id]/resourceGroups/[rg-name]
```

**Required permissions for common tasks**:
| Task | Required Role | Scope |
|------|---------------|-------|
| Create Resource Group | Contributor | Subscription |
| Deploy Resources | Contributor | Resource Group |
| Create Service Principal | Application Administrator | Azure AD |
| Manage RBAC | User Access Administrator | Subscription/RG |

---

## Getting Help

### Before Escalating

Prepare the following information:

- [ ] Exact error message (copy/paste, not screenshot)
- [ ] Terraform version: `terraform version`
- [ ] Azure CLI version: `az version`
- [ ] Full command that failed
- [ ] Relevant configuration (sanitized)
- [ ] Debug logs (if applicable)
- [ ] Steps to reproduce
- [ ] What you've already tried

### Self-Service Resources

1. **Search Documentation**:
   - [Internal docs search]
   - Microsoft Learn
   - Terraform Registry

2. **Check Known Issues**:
   - [Team known issues tracker]
   - Terraform GitHub Issues
   - Azure Service Health

3. **Community Resources**:
   - HashiCorp Discuss
   - Microsoft Q&A
   - Stack Overflow

### Escalation Path

1. **Check with peer**: Ask team members in [team channel]
2. **Internal support**: Post in [internal support channel]
3. **Senior engineer**: Tag [on-call engineer] if urgent
4. **Vendor support**:
   - Azure Support: [Portal link to support]
   - HashiCorp Support: [If enterprise]

---

## Common Error Messages Reference

Quick reference for frequently seen errors:

| Error Message | Quick Fix | Details |
|---------------|-----------|---------|
| `Error: building account...` | Run `az login` | [Link to full solution](#) |
| `Error: state lock...` | Wait or force unlock | [Link](#) |
| `Error: provider not found` | Run `terraform init` | [Link](#) |
| `Error: Unsupported Terraform version` | Upgrade Terraform | [Link](#) |
| `error: 403 Forbidden` | Check permissions | [Link](#) |

---

## Diagnostic Commands Cheat Sheet

### Quick Health Checks

```bash
# Authentication status
az account show

# Terraform setup
terraform version
terraform validate

# State status
terraform state list

# Azure resource status
az resource list --resource-group [rg-name]

# Provider status
terraform providers

# Configuration check
terraform fmt -check -diff
```

### Detailed Diagnostics

```bash
# Full Terraform debug
TF_LOG=DEBUG terraform apply

# Azure CLI debug
az group list --debug

# Test Azure connectivity
az rest --method get --url https://management.azure.com/subscriptions?api-version=2020-01-01

# Check state backend
az storage blob list --account-name [sa-name] --container-name [container]
```

---

## Related Documentation

**Concepts**:
- [Related Concept]: Understanding underlying principles

**How-To Guides**:
- [Related How-To]: Proper procedure to avoid these issues

**Reference**:
- [Command Reference]: Full command documentation
- [Configuration Reference]: All configuration options

**Other Troubleshooting Guides**:
- [Related Troubleshooting Guide 1]
- [Related Troubleshooting Guide 2]

---

## Glossary Terms

From [Glossary](../config/glossary.yaml):

- **[term_1]**: [Context for troubleshooting]
- **[term_2]**: [Relevance to errors]

---

**Document Metadata**:
- **Last Updated**: [YYYY-MM-DD]
- **Reviewed By**: [Name/Team]
- **Next Review**: [YYYY-MM-DD]
- **Coverage**: [List of errors/issues covered]
- **Change History**: [Link]

---

**Feedback**: Was this helpful? Did you encounter an issue not listed here? [Report it](link)
