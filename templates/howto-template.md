---
document_id: howto-[short-descriptive-id]
document_type: howto
skill_level: [day1|week1-4|month1-2|month3-6|month6-12|expert]
topics: [list, of, topics]
technologies: [terraform_v1.5+, azure_cli_2.50+, powershell_7.4+, azuredevops]
prerequisites:
  - [document_id_of_prerequisite_1]
  - [document_id_of_prerequisite_2]
learning_outcomes:
  - [Specific task skill gained]
  - [Another practical skill]
estimated_time: [minutes to complete]
last_reviewed: [YYYY-MM-DD]
review_status: [current|needs_review|deprecated]
search_keywords:
  - "[how to do X]"
  - "[step by step X]"
  - "[X tutorial]"
  - "[perform X task]"
related_documents:
  - [related_document_id_1]
  - [related_document_id_2]
glossary_terms:
  - [term_from_glossary]
  - [another_term]
difficulty: [beginner|intermediate|advanced]
---

# How to [Task Title]

## Overview

**Goal**: In one sentence, state what you will accomplish by following this guide.

**Prerequisites**:
- ✓ [Prerequisite 1 - be specific]
- ✓ [Prerequisite 2 - include versions if relevant]
- ✓ [Prerequisite 3 - mention required permissions/access]

**What You'll Learn**:
- [Specific skill or knowledge point 1]
- [Specific skill or knowledge point 2]
- [Specific skill or knowledge point 3]

**Estimated Time**: [X] minutes

## Before You Begin

### Required Tools and Access
- [Tool 1] version [X.Y] or higher
- [Tool 2] with [specific configuration]
- Access to [Azure subscription/resource/service]

### Verify Prerequisites

Run these commands to confirm you're ready to proceed:

```bash
# Check Terraform version
terraform version
# Expected output: Terraform v1.5.0 or higher

# Check Azure CLI version
az version
# Expected output: azure-cli 2.50.0 or higher

# Verify Azure authentication
az account show
# Should display your subscription details
```

### Setup Checklist

Before proceeding, ensure:
- [ ] All required tools are installed
- [ ] You have the necessary permissions
- [ ] You understand the [Related Concept](link)
- [ ] You have backed up any existing configuration (if applicable)

## Step-by-Step Instructions

### Step 1: [First Action - Be Specific and Action-Oriented]

**Purpose**: Explain why this step is necessary.

**Action**:

1. Navigate to your project directory:
   ```bash
   cd /path/to/your/project
   ```

2. Create the required file structure:
   ```bash
   mkdir -p [directory-structure]
   touch [file-name]
   ```

3. [Next action]:
   ```bash
   [command with actual values]
   ```

**Expected Result**:
- You should see [specific output]
- The directory structure should look like:
  ```
  project/
  ├── file1
  ├── file2
  └── directory/
      └── file3
  ```

#### Checkpoint ✓

At this point, verify:
- [ ] [Specific condition to check]
- [ ] [Another verification point]
- [ ] [Files exist in correct locations]

If something doesn't match, see [Troubleshooting](#troubleshooting) below.

---

### Step 2: [Second Action]

**Purpose**: [Why this step is important]

**Action**:

Create or edit `[filename]` with the following content:

```hcl
# [Language] - [Brief description of code block]
[actual code here]

# Comments explaining key parts
variable "example" {
  description = "Clear description"
  type        = string
  default     = "value"
}
```

**Key Configuration Points**:
- **`variable "example"`**: Explanation of this setting
- **`type = string`**: Why this type is used
- **`default = "value"`**: Significance of this default

**Customization**:
You should modify the following based on your environment:
- `[field1]`: Set this to [your value]
- `[field2]`: Change to match your [requirement]

#### Checkpoint ✓

Validate your configuration:
```bash
# Run validation command
[validation command]

# Expected output:
# [What you should see]
```

---

### Step 3: [Third Action]

**Purpose**: [Why this step matters]

**Action**:

1. Run the initialization command:
   ```bash
   [command]
   ```

   **Expected output**:
   ```
   [Example output]
   Initializing provider plugins...
   Success! Ready to proceed.
   ```

2. Review the plan:
   ```bash
   [plan command]
   ```

   This will show you what changes will be made. Review carefully:
   - **Resources to create**: [Expected count]
   - **Resources to modify**: Should be 0 (unless updating existing)
   - **Resources to delete**: Should be 0

3. Apply the configuration:
   ```bash
   [apply command]
   ```

   You'll be prompted to confirm. Type `yes` when you're ready.

#### Checkpoint ✓

Verify the deployment:
- [ ] Command completed without errors
- [ ] All expected resources were created
- [ ] No unexpected warnings

---

### Step 4: [Verification and Testing]

**Purpose**: Confirm everything works as expected.

**Action**:

1. **Verify in Azure Portal**:
   - Navigate to [Portal URL or location]
   - You should see [expected resource/configuration]
   - Check that [specific settings] match your configuration

2. **Verify using Azure CLI**:
   ```bash
   az [resource] show --name [name] --resource-group [rg]
   ```

   **Look for**:
   - `"provisioningState": "Succeeded"`
   - `"[property]": "[expected value]"`

3. **Test functionality**:
   ```bash
   # Perform a test action
   [test command]
   ```

   **Expected result**: [What should happen]

## Complete Example

Here's the full working example for reference:

```hcl
# Complete example - can be copied and customized
# File: main.tf

[Full working code example]
```

```bash
# Commands to deploy the above example
terraform init
terraform plan
terraform apply -auto-approve
```

**Result**: This example creates [describe what's created] suitable for [use case].

## What You've Accomplished

By completing this guide, you have:
- ✓ [Achievement 1]
- ✓ [Achievement 2]
- ✓ [Achievement 3]

You should now be able to:
- [Capability 1]
- [Capability 2]
- [Capability 3]

## Cleanup (Optional)

If this was a learning exercise and you want to remove the resources:

```bash
# WARNING: This will delete all resources created in this guide
terraform destroy

# Confirm when prompted by typing 'yes'
```

**Cleanup verification**:
```bash
# Verify resources are gone
az [resource] list --resource-group [rg]
# Should return empty or show "not found"
```

## Troubleshooting

### Issue: [Common Problem 1]

**Symptoms**:
- Error message: `[exact error message]`
- What you see: [description]

**Cause**: [Why this happens]

**Solution**:
1. [First step to fix]
2. [Second step]
3. [Third step]

```bash
# Fix command(s)
[commands to resolve]
```

**Prevention**: To avoid this in future: [preventive measure]

---

### Issue: [Common Problem 2]

**Symptoms**:
- [What indicates this problem]

**Cause**: [Root cause]

**Solution**:
[Steps to resolve]

---

### Issue: [Common Problem 3]

**Symptoms**:
- [Problem indicators]

**Cause**: [Why it occurs]

**Solution**:
[Resolution steps]

**Still stuck?** Check the [Troubleshooting Reference](link) or [contact team support].

## Next Steps

Now that you've completed this guide, here's what to learn next:

**Immediate next steps**:
- [ ] [Follow-on task to reinforce learning]
- [ ] [Related task to expand skills]

**Continue your learning path**:
- **Build on this skill**: [Link to advanced guide]
- **Learn a complementary skill**: [Link to related guide]
- **Understand the concepts**: [Link to concept documentation]

**Suggested progression**:
1. [Next recommended guide]
2. [Second recommendation]
3. [Third recommendation]

## Related Documentation

**Concepts**:
- [Concept Name]: Understand the "why" behind this task
- [Another Concept]: Related conceptual knowledge

**How-To Guides**:
- [Related Task 1]: Similar procedures
- [Related Task 2]: Complementary skills

**Reference**:
- [Reference Doc 1]: Technical specifications
- [Reference Doc 2]: Command reference

**Troubleshooting**:
- [Common Issues]: Comprehensive troubleshooting guide

## External Resources

- **Microsoft Documentation**: [URL]
- **Terraform Registry**: [URL]
- **Best Practices**: [URL]
- **Community Forum**: [URL]

## Glossary Terms Used

Terms defined in the [Glossary](../config/glossary.yaml):

- **[term_1]**: [Brief context for this guide]
- **[term_2]**: [How it's used here]
- **[term_3]**: [Relevance to this task]

---

**Document Metadata**:
- **Last Updated**: [YYYY-MM-DD]
- **Reviewed By**: [Name/Team]
- **Next Review**: [YYYY-MM-DD]
- **Tested On**: [Environment/Version details]
- **Change History**: [Link to git history]

---

**Feedback**: Did this guide work for you? [Link to feedback form or contact]
