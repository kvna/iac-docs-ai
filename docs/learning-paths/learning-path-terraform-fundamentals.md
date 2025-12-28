---
document_id: learning-path-terraform-fundamentals
document_type: learning-path
skill_level: day1
topics: [terraform, learning, curriculum, getting-started, week1-4]
technologies: [terraform_v1.5+, azure, git]
search_keywords:
  - "terraform learning path"
  - "terraform curriculum"
  - "learn terraform"
  - "terraform training"
  - "terraform beginner"
  - "terraform roadmap"
estimated_time: 480
last_reviewed: 2025-12-28
review_status: current
prerequisites:
  - howto-environment-setup
learning_outcomes:
  - Deploy infrastructure using Terraform
  - Understand Infrastructure as Code principles
  - Manage Terraform state safely
  - Use modules for code reusability
  - Troubleshoot common errors
  - Collaborate with team using Git
related_documents:
  - concept-iac-overview
  - howto-environment-setup
  - howto-terraform-state-management
  - concept-terraform-modules
  - troubleshooting-common-errors
  - reference-naming-conventions
---

# Learning Path: Terraform Fundamentals

## Overview

**Goal**: Master Terraform basics and deploy production-ready infrastructure on Azure within 4 weeks.

**Time commitment**: 8 hours/week for 4 weeks (32 hours total)

**Who this is for**:
- Infrastructure engineers new to Terraform
- Developers wanting to understand IaC
- Anyone responsible for Azure infrastructure

**What you'll learn**:
- Core Terraform concepts and workflow
- Azure resource provisioning
- State management and collaboration
- Best practices and troubleshooting
- Team workflows with Git

**Prerequisites**:
- ✓ Basic command-line experience
- ✓ Azure subscription access
- ✓ Git basics (clone, commit, push)
- ✓ Text editor (VS Code recommended)

---

## Learning Path Structure

### Week 1: Foundations (8 hours)
**Focus**: Understanding IaC and getting your environment ready

### Week 2: Core Terraform (8 hours)
**Focus**: Writing and deploying Terraform code

### Week 3: Collaboration & State (8 hours)
**Focus**: Team workflows and state management

### Week 4: Best Practices & Production (8 hours)
**Focus**: Modules, standards, and production readiness

---

## Week 1: Foundations

### Day 1: Infrastructure as Code Concepts (2 hours)

**📖 Read:**
1. [What is Infrastructure as Code?](../day1/concept-iac-overview.md) - 15 min
2. External: [Terraform Introduction](https://developer.hashicorp.com/terraform/intro) - 30 min

**✏️ Exercise:**
- Write down 3 problems in your current infrastructure workflow
- Identify which ones IaC could solve
- Share with mentor or team

**✅ Checkpoint:**
- [ ] Can explain what IaC is to a colleague
- [ ] Can list 3 benefits of IaC
- [ ] Understand declarative vs imperative

---

### Day 2: Environment Setup (2 hours)

**📖 Read:**
1. [How to Set Up Your Environment](../day1/howto-environment-setup.md) - 45 min

**🔧 Lab:**
1. Install Terraform, Azure CLI, PowerShell 7, Git
2. Authenticate to Azure (`az login`)
3. Create a test resource group via CLI:
   ```bash
   az group create --name rg-learn-test --location northeurope
   az group delete --name rg-learn-test --yes
   ```
4. Initialize a new Git repository

**✅ Checkpoint:**
- [ ] All tools installed and working
- [ ] Successfully authenticated to Azure
- [ ] Created and deleted a resource group
- [ ] Git repository initialized

---

### Day 3: First Terraform Code (2 hours)

**🔧 Lab: Your First Resource**

Create a directory structure:
```
terraform-learning/
├── week1/
│   └── first-resource/
│       └── main.tf
```

Write your first Terraform code (`main.tf`):
```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "learning" {
  name     = "rg-terraform-learning"
  location = "northeurope"

  tags = {
    Purpose     = "Learning"
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}
```

**Execute:**
```bash
terraform init
terraform plan
terraform apply
# Check Azure Portal - your resource group exists!
terraform destroy
```

**✅ Checkpoint:**
- [ ] Created a .tf file
- [ ] Ran `terraform init` successfully
- [ ] Understood `terraform plan` output
- [ ] Created and destroyed a resource
- [ ] Saw the resource in Azure Portal

---

### Day 4: Terraform Workflow & Review (2 hours)

**📖 Read:**
1. [Terraform Workflow](https://developer.hashicorp.com/terraform/intro/core-workflow) - 20 min
2. [Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) - 30 min

**🔧 Lab: Expand Your Code**

Add more resources to `main.tf`:
```hcl
# Add a storage account
resource "azurerm_storage_account" "learning" {
  name                     = "stlearn${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.learning.name
  location                 = azurerm_resource_group.learning.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = azurerm_resource_group.learning.tags
}

# Generate a random suffix
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}
```

**✅ Checkpoint:**
- [ ] Understand the write -> plan -> apply workflow
- [ ] Created multiple resources
- [ ] Understand resource dependencies
- [ ] Committed code to Git

---

## Week 2: Core Terraform

### Day 1: Variables & Outputs (2 hours)

**📖 Read:**
1. [Terraform Variables](https://developer.hashicorp.com/terraform/language/values/variables) - 30 min
2. [Terraform Outputs](https://developer.hashicorp.com/terraform/language/values/outputs) - 20 min

**🔧 Lab: Parameterize Your Code**

Create `variables.tf`:
```hcl
variable "location" {
  description = "Azure region"
  type        = string
  default     = "northeurope"
}

variable "environment" {
  description = "Environment name"
  type        = string

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be dev, test, or prod."
  }
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
```

Create `outputs.tf`:
```hcl
output "resource_group_id" {
  description = "Resource group ID"
  value       = azurerm_resource_group.learning.id
}

output "storage_account_name" {
  description = "Storage account name"
  value       = azurerm_storage_account.learning.name
}
```

Create `terraform.tfvars`:
```hcl
environment = "dev"
tags = {
  CostCenter = "IT-Learning"
  Owner      = "YourName"
}
```

**✅ Checkpoint:**
- [ ] Refactored code to use variables
- [ ] Created outputs
- [ ] Used a .tfvars file
- [ ] Validated variable constraints work

---

### Day 2: State Deep Dive (2 hours)

**📖 Read:**
1. [How to Manage Terraform State](../week1-4/howto-terraform-state-management.md) - 30 min

**🔧 Lab: Local vs Remote State**

1. Examine local state file:
   ```bash
   cat terraform.tfstate | jq
   # Notice it contains resource IDs, metadata
   ```

2. Configure remote backend (following the howto guide)
3. Migrate local state to remote
4. Test state locking with a teammate

**✅ Checkpoint:**
- [ ] Understand what's in terraform.tfstate
- [ ] Configured remote backend in Azure Storage
- [ ] Migrated existing state
- [ ] Tested state locking

---

### Day 3: Troubleshooting (2 hours)

**📖 Read:**
1. [Troubleshooting Common Errors](../day1/troubleshooting-common-errors.md) - 20 min

**🔧 Lab: Intentional Errors**

Practice fixing common errors:

1. **Auth error**: Log out of Azure CLI, try to run Terraform
2. **Syntax error**: Add invalid HCL syntax, run `terraform validate`
3. **State lock**: Start a long-running `terraform apply`, try to run another
4. **Name conflict**: Try to create a resource that already exists
5. **Quota error**: (if possible) try to exceed subscription limits

**✅ Checkpoint:**
- [ ] Debugged 5 different error types
- [ ] Know where to find error codes
- [ ] Can enable debug logging
- [ ] Comfortable reading error messages

---

### Day 4: Naming Conventions (2 hours)

**📖 Read:**
1. [Reference: Naming Conventions](../reference/reference-naming-conventions.md) - 20 min

**🔧 Lab: Refactor with Standards**

Refactor your code to follow naming conventions:
```hcl
# Before
name = "myresourcegroup"

# After
name = "rg-${var.workload}-${var.environment}-${var.region_code}"

# Variables
variable "workload" {
  default = "learning"
}

variable "region_code" {
  default = "northeu"
}
```

**✅ Checkpoint:**
- [ ] All resources follow naming convention
- [ ] Names include workload, environment, region
- [ ] Storage account names have no hyphens
- [ ] Resource tags are consistent

---

## Week 3: Collaboration & State

### Day 1: Git Workflows for Infrastructure (2 hours)

**📖 Read:**
1. [Git Branching](https://git-scm.com/book/en/v2/Git-Branching-Branching-Workflows) - 30 min

**🔧 Lab: Feature Branch Workflow**

1. Create a feature branch:
   ```bash
   git checkout -b feature/add-key-vault
   ```

2. Add a new resource (Key Vault)
3. Commit changes
4. Create a pull request (if using Azure DevOps/GitHub)
5. Merge to main after review

**✅ Checkpoint:**
- [ ] Created feature branch
- [ ] Made infrastructure changes
- [ ] Opened a pull request
- [ ] Merged after review

---

### Day 2: Modules Introduction (2 hours)

**📖 Read:**
1. [Concept: Terraform Modules](../week1-4/concept-terraform-modules.md) - 30 min

**🔧 Lab: Create Your First Module**

Create a resource group module:
```
modules/
└── resource-group/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

Use it:
```hcl
module "dev_rg" {
  source = "../../modules/resource-group"
  name   = "rg-myapp-dev-northeu"
}
```

**✅ Checkpoint:**
- [ ] Created a module
- [ ] Used module in main code
- [ ] Understand module inputs/outputs
- [ ] Can access module outputs

---

### Day 3: Multi-Environment Setup (2 hours)

**🔧 Lab: Dev, Test, Prod**

Create environment-specific configurations:
```
terraform/
├── modules/
│   └── network/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── backend.hcl
│   │   └── terraform.tfvars
│   ├── test/
│   └── prod/
```

Deploy the same infrastructure to each environment with different parameters.

**✅ Checkpoint:**
- [ ] 3 separate environments
- [ ] Each with its own state file
- [ ] Different configurations per environment
- [ ] Can deploy/destroy independently

---

### Day 4: Review & Practice (2 hours)

**🔧 Mini-Project:**

Build a complete application infrastructure:
- Resource group
- Virtual network with subnets
- Storage account
- Key Vault
- App Service

Requirements:
- Use modules
- Multiple environments (dev/prod)
- Follow naming conventions
- Remote state
- Git workflow

**✅ Checkpoint:**
- [ ] Multi-resource deployment
- [ ] All best practices applied
- [ ] Documented in README
- [ ] Code reviewed by mentor

---

## Week 4: Production Readiness

### Day 1: Security Best Practices (2 hours)

**📖 Read:**
1. [PRODUCTION_ARCHITECTURE.md](../../PRODUCTION_ARCHITECTURE.md) - Security sections - 45 min

**🔧 Lab: Secure Your Infrastructure**

Add security controls:
- Enable encryption
- Configure network rules
- Use Managed Identities
- Set up diagnostic logging

**✅ Checkpoint:**
- [ ] Storage encryption enabled
- [ ] Key Vault access policies configured
- [ ] Network restrictions applied
- [ ] Diagnostic logs enabled

---

### Day 2: Cost Optimization (2 hours)

**📖 Read:**
1. [Azure Pricing](https://azure.microsoft.com/pricing/) - 20 min

**🔧 Lab: Right-Size Resources**

Review your deployed resources:
- Are you using the right SKU?
- Can you use cheaper storage tiers?
- Should resources be deleted when not in use?

Create a cost estimate using Azure Pricing Calculator.

**✅ Checkpoint:**
- [ ] Reviewed all resource SKUs
- [ ] Calculated monthly costs
- [ ] Identified optimization opportunities
- [ ] Created teardown automation

---

### Day 3: Documentation (2 hours)

**🔧 Lab: Document Everything**

Create documentation:
- README.md with setup instructions
- Architecture diagram (text or visual)
- Runbook for common operations
- Troubleshooting guide for your project

**✅ Checkpoint:**
- [ ] README with clear instructions
- [ ] Architecture documented
- [ ] Runbooks created
- [ ] Team can use your code without asking questions

---

### Day 4: Final Project (2 hours)

**🎓 Capstone Project:**

Deploy a complete, production-ready infrastructure:

**Requirements:**
- At least 5 different Azure services
- 3 environments (dev/test/prod)
- Modular code structure
- Remote state with locking
- Follows naming conventions
- Security best practices
- Cost optimized
- Fully documented
- Git workflow
- CI/CD ready (bonus)

**Deliverables:**
- Working Terraform code
- Documentation
- Presentation to team (10 min)

**✅ Final Checkpoint:**
- [ ] All requirements met
- [ ] Code reviewed by senior engineer
- [ ] Successfully presented to team
- [ ] Ready to work on production infrastructure

---

## Assessment & Certification

### Knowledge Check

After completing this path, you should be able to:

**Concepts:**
- [ ] Explain IaC principles
- [ ] Describe Terraform workflow
- [ ] Understand state management
- [ ] Know when to use modules

**Practical Skills:**
- [ ] Write Terraform code from scratch
- [ ] Deploy resources to Azure
- [ ] Manage state safely
- [ ] Troubleshoot common errors
- [ ] Follow naming conventions
- [ ] Use Git for infrastructure code
- [ ] Collaborate with a team
- [ ] Apply security best practices

**Project Work:**
- [ ] Completed all 16 daily labs
- [ ] Passed capstone project
- [ ] Contributed to team's Terraform codebase

### Next Steps

After completing this path:

1. **Advanced Terraform** (next learning path)
   - Advanced state manipulation
   - Complex modules
   - Terraform Cloud/Enterprise
   - Policy as Code (Sentinel/OPA)

2. **Specialization Paths**
   - Azure networking deep dive
   - Security and compliance
   - Multi-cloud (AWS/GCP)
   - Kubernetes infrastructure

3. **Certifications**
   - HashiCorp Terraform Associate
   - Microsoft Azure Administrator

## Resources

### Internal
- Team Wiki: [link]
- Team Chat: #terraform-help
- Office Hours: Fridays 2-3pm
- Code Reviews: #infrastructure-reviews

### External
- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
- [Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Azure Architecture Center](https://learn.microsoft.com/azure/architecture/)

### Books
- "Terraform: Up & Running" by Yevgeniy Brikman
- "Infrastructure as Code" by Kief Morris

## Support

**Stuck on something?**
1. Check troubleshooting guide
2. Search team documentation
3. Ask in #terraform-help
4. Schedule office hours
5. Pair with a mentor

**Found a gap in this learning path?**
- Submit feedback via [documentation gap report]
- Suggest improvements
- Add examples from your experience

---

**Congratulations on starting your Terraform journey! Remember: everyone struggles at first. Keep practicing, ask questions, and you'll be deploying infrastructure like a pro in no time.**

**Next document**: [How to Set Up Your Environment](../day1/howto-environment-setup.md)
