---
document_id: concept-iac-overview
document_type: concept
skill_level: day1
topics: [iac, fundamentals, philosophy]
technologies: [terraform_v1.5+, azure]
prerequisites:
  - "None - this is a starting point"
learning_outcomes:
  - Understand what Infrastructure as Code means
  - Explain why IaC is valuable
  - Identify when to use IaC vs manual processes
estimated_time: 15
last_reviewed: 2025-12-27
review_status: current
search_keywords:
  - "what is infrastructure as code"
  - "what is iac"
  - "why use infrastructure as code"
  - "infrastructure as code explained"
  - "iac benefits"
  - "declarative infrastructure"
related_documents:
  - howto-environment-setup
  - concept-terraform-workflow
  - learning-path-day1
glossary_terms:
  - iac
  - declarative
  - terraform
  - azure
---

# What is Infrastructure as Code?

## Overview

**Purpose**: Understand the fundamental concept of Infrastructure as Code and why it's essential for modern cloud operations.

**Use this concept when**: You're new to IaC or need to explain it to others.

**Avoid this when**: You're looking for step-by-step instructions (see How-To guides instead).

## What is Infrastructure as Code (IaC)?

Infrastructure as Code is the practice of managing and provisioning your cloud infrastructure through machine-readable definition files, rather than through manual point-and-click processes or interactive configuration tools.

Think of it this way: instead of logging into the Azure Portal and clicking buttons to create a virtual machine, you write a text file that describes what you want (a virtual machine with specific properties), and a tool like Terraform reads that file and creates it for you.

### A Simple Analogy

**Manual Infrastructure** (without IaC):
- Like building a house by telling each worker individually what to do
- If you need another identical house, you have to give all the instructions again
- Easy to forget a step or make a mistake
- Hard to keep track of what you've built

**Infrastructure as Code**:
- Like having architectural blueprints for a house
- You can build identical houses from the same blueprints
- Every detail is documented
- You can see exactly what the house should look like

## How It Works

### Traditional Approach (Manual)

```
You ──click──▶ Azure Portal ──creates──▶ Resources
                                              │
                                              ▼
                                      (Undocumented,
                                       hard to replicate)
```

1. Log into Azure Portal
2. Click "Create Resource"
3. Fill out forms
4. Click "Create"
5. **Result**: Resource exists, but no record of exactly how it was created

### IaC Approach

```
You ──write──▶ Code File ──read by──▶ Terraform ──creates──▶ Resources
      (main.tf)                                                  │
         │                                                       ▼
         └──────────────────────▶ (Documented,
                                   version-controlled,
                                   repeatable)
```

1. Write a configuration file (e.g., `main.tf`)
2. Describe what you want in that file
3. Run a command (`terraform apply`)
4. **Result**: Resources created exactly as described, with full documentation

## Key Characteristics

### 1. Declarative

You describe **what** you want, not **how** to create it.

**Example**:
```hcl
# You declare: "I want a resource group named rg-example in East US 2"
resource "azurerm_resource_group" "example" {
  name     = "rg-example-prod-eastus2"
  location = "eastus2"
}

# Terraform figures out how to make that happen
```

You don't need to know the specific API calls or sequence of operations—just describe the desired end state.

### 2. Version Controlled

IaC files are just text files, so they can be stored in version control systems like Git.

**Benefits**:
- See who changed what and when
- Revert to previous versions if needed
- Collaborate with team members
- Track the complete history of your infrastructure

### 3. Repeatable

The same code produces the same infrastructure every time.

```
Same Code + Same Environment = Same Infrastructure
```

**Example**:
- Create development environment on Monday
- Use exact same code to create testing environment on Tuesday
- Guaranteed to be identical

### 4. Testable

Because infrastructure is code, you can test it:
- Validate syntax before deploying
- Preview changes before applying them
- Run automated tests on infrastructure code
- Catch errors before they reach production

## Real-World Example

### Scenario: Creating a Storage Account

**Without IaC** (Manual Portal):
1. Log into Azure Portal (2 minutes)
2. Navigate to Storage Accounts (1 minute)
3. Click Create (30 seconds)
4. Fill out form:
   - Resource group: ??? (was it rg-app-prod or rg-prod-app?)
   - Name: ??? (what naming convention did we use?)
   - Region: ??? (which region are we using?)
   - Replication: ??? (what did we choose last time?)
   - Performance: ??? (standard or premium?)
5. Guess settings or look at existing storage account
6. Click Create (5 minutes of form-filling)
7. **Total time**: ~10 minutes, prone to errors

**With IaC**:
```hcl
resource "azurerm_storage_account" "app" {
  name                     = "stmyappprodeastus2001"
  resource_group_name      = azurerm_resource_group.app.name
  location                 = azurerm_resource_group.app.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    Environment = "prod"
    Application = "myapp"
  }
}
```

Then run:
```bash
terraform apply
```

**Result**:
- Exact same configuration every time
- Documented in code
- Version controlled
- Can be replicated instantly
- **Time for subsequent creations**: ~1 minute

## Benefits and Trade-offs

### Benefits

**1. Consistency**
- No more "configuration drift" (resources changing over time)
- Every environment matches the code
- Reduces "it works on my machine" problems

**2. Speed**
- After initial setup, deployment is much faster
- Can create entire environments in minutes
- Automation reduces manual effort

**3. Documentation**
- The code **is** the documentation
- Always up-to-date (unlike separate docs)
- New team members can read the code to understand infrastructure

**4. Collaboration**
- Multiple people can work on same infrastructure
- Code review process ensures quality
- Version control prevents conflicts

**5. Disaster Recovery**
- If infrastructure is destroyed, recreate from code
- No guesswork about how it was configured
- Faster recovery time

**6. Cost Management**
- Easily spin down non-production environments when not needed
- Recreate them when needed
- Track infrastructure changes that affect cost

### Trade-offs

**1. Learning Curve**
- Need to learn new tools (Terraform, HCL language)
- Need to understand infrastructure concepts
- Initial investment in training
- **Our approach**: This documentation system helps you learn progressively

**2. Initial Time Investment**
- First time creating infrastructure with code takes longer than clicking
- Need to write and test code
- **Payoff**: Subsequent deployments are much faster

**3. Requires Discipline**
- Team must commit to using IaC, not manual changes
- Need processes and governance
- Code review requirements
- **Our approach**: Team standards and review processes established

## When to Apply This Concept

### Use Infrastructure as Code when:

- ✓ Creating any cloud infrastructure (even a single resource)
- ✓ Need to create multiple environments (dev, test, prod)
- ✓ Working in a team
- ✓ Need to audit changes
- ✓ Want to prevent manual errors
- ✓ Need to replicate infrastructure
- ✓ Building production systems

### Consider manual approaches when:

- ✗ One-time emergency fix (but document what you changed!)
- ✗ Exploring/learning Azure features in personal sandbox
- ✗ Troubleshooting specific issues (but capture findings in code later)

**Note**: Even for exceptions above, it's often better to use IaC for consistency.

## Common Misconceptions

**Misconception**: "IaC is only for large, complex infrastructures"
**Reality**: IaC provides value even for simple setups. A single resource group with a few resources still benefits from documentation and repeatability.

**Misconception**: "Writing code is slower than clicking in the portal"
**Reality**: The first time might be slower, but you save time on every subsequent deployment and reduce errors significantly.

**Misconception**: "IaC replaces the need to understand Azure"
**Reality**: You still need to understand Azure concepts. IaC is a tool for managing them, not a replacement for knowledge.

**Misconception**: "Once infrastructure is created, you don't need to touch the code"
**Reality**: Infrastructure evolves. IaC makes managing changes safer and more predictable. All changes should go through the code.

## Relationship to Other Concepts

### IaC and Terraform

- **IaC** is the **concept** (the "what" and "why")
- **Terraform** is a **tool** that implements IaC (the "how")
- Other IaC tools exist (ARM templates, Bicep, CloudFormation), but we use Terraform

### IaC and Azure

- **Azure** is the cloud platform (the infrastructure)
- **IaC** is the approach to managing that infrastructure
- You use IaC (via Terraform) to create and manage Azure resources

### IaC and DevOps

- **DevOps** is a culture and set of practices
- **IaC** is a key practice within DevOps
- Enables "continuous delivery" of infrastructure changes
- Aligns with "version control everything" principle

## Practical Implications

### What This Means for Your Work

1. **All Infrastructure Changes Go Through Code**
   - Don't click in the portal to make changes
   - Update the Terraform code instead
   - Let Terraform apply the changes

2. **Code Review for Infrastructure**
   - Infrastructure changes are reviewed like software code
   - Increases quality and knowledge sharing
   - Catches errors before production

3. **Git is Your Source of Truth**
   - The code in Git describes what infrastructure should exist
   - If portal shows something different, the code wins
   - Update code to match desired state

4. **Environments Are Identical**
   - Dev, test, and prod use same code with different parameters
   - Reduces "works in test but fails in prod" issues
   - Changes can be tested before production

## Further Reading

**Next Steps**:
- To start using IaC: [How to Set Up Your IaC Development Environment](howto-environment-setup.md)
- To understand the workflow: [Understanding the Terraform Workflow](../week1-4/concept-terraform-workflow.md)
- To deploy your first resource: [Your First Terraform Deployment](../week1-4/howto-terraform-first-deployment.md)

**External Resources**:
- [Microsoft: What is Infrastructure as Code?](https://learn.microsoft.com/en-us/devops/deliver/what-is-infrastructure-as-code)
- [HashiCorp: Introduction to Infrastructure as Code with Terraform](https://www.terraform.io/intro)
- [Azure Cloud Adoption Framework: IaC](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/considerations/infrastructure-as-code)

## Glossary Terms Used

All terms below are defined in the [Glossary](../../config/glossary.yaml):

- **IaC (Infrastructure as Code)**: The practice of managing infrastructure through code files instead of manual processes
- **Declarative**: Describing the desired end state rather than step-by-step instructions
- **Terraform**: The open-source IaC tool we use to manage Azure infrastructure
- **Azure**: Microsoft's cloud platform where our infrastructure runs

---

**Document Metadata**:
- **Last Updated**: 2025-12-27
- **Reviewed By**: IaC Team Lead
- **Next Review**: 2026-03-27
- **Change History**: Initial version
