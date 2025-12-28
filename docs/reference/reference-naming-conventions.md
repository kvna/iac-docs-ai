---
document_id: reference-naming-conventions
document_type: reference
skill_level: week1-4
topics: [standards, naming, conventions, best-practices]
technologies: [azure, terraform_v1.5+]
prerequisites:
  - concept-iac-overview
learning_outcomes:
  - Apply team naming standards to Azure resources
  - Construct valid resource names following convention
  - Understand rationale behind naming patterns
estimated_time: 20
last_reviewed: 2025-12-27
review_status: current
search_keywords:
  - "azure naming convention"
  - "resource naming standards"
  - "how to name resources"
  - "naming best practices"
  - "resource naming pattern"
related_documents:
  - reference-tagging-standards
  - howto-terraform-first-deployment
glossary_terms:
  - naming_convention
  - resource_group
  - storage_account
  - virtual_network
reference_type: standard
---

# Azure Resource Naming Convention Standards

## Purpose

This reference defines the team's standardized approach to naming Azure resources. Use this document to construct names for all Azure resources created through Terraform.

**When to use this reference**:
- When creating any new Azure resource
- When reviewing Terraform code for naming compliance
- When documenting infrastructure
- When troubleshooting or searching for resources

## Quick Reference

### Standard Pattern

```
[resource-type]-[workload/application]-[environment]-[region]-[instance]
```

### Example Names

| Resource Type | Example | Breakdown |
|---------------|---------|-----------|
| Resource Group | `rg-myapp-prod-eastus2` | rg + myapp + prod + eastus2 |
| Storage Account | `stmyappprodeastus2001` | st + myapp + prod + eastus2 + 001 |
| Key Vault | `kv-myapp-prod-eastus2` | kv + myapp + prod + eastus2 |
| Virtual Network | `vnet-myapp-prod-eastus2` | vnet + myapp + prod + eastus2 |
| App Service | `app-myapp-prod-eastus2` | app + myapp + prod + eastus2 |

## Detailed Specification

### Naming Pattern Components

#### 1. Resource Type Prefix

**Purpose**: Immediately identify resource type

**Format**: Lowercase abbreviation, usually 2-6 characters

**Rules**:
- Must be from approved abbreviations list (see table below)
- Lowercase only
- No special characters

#### 2. Workload/Application Name

**Purpose**: Identify the application or workload

**Format**: Short descriptive name

**Rules**:
- Lowercase alphanumeric
- Hyphens allowed (except for resources that don't support them)
- 3-12 characters recommended
- Should be consistent across all resources for the same workload
- Use acronyms or short names (e.g., "myapp" not "my-application-platform")

**Examples**:
- `ecommerce`
- `dataplatform`
- `apigateway`
- `sharedservices`

#### 3. Environment

**Purpose**: Distinguish between lifecycle stages

**Format**: Standard environment code

**Valid Values**:
- `dev` - Development
- `test` - Testing/QA
- `stage` - Staging/Pre-production
- `prod` - Production
- `sandbox` - Experimental/learning (automatically deleted)

**Rules**:
- Must use exactly these values (lowercase)
- No custom environment names
- Sandbox environments may be auto-deleted after 7 days

#### 4. Azure Region

**Purpose**: Indicate geographic location

**Format**: Azure region short code

**Common Regions**:
| Region Name | Code |
|-------------|------|
| East US 2 | `eastus2` |
| West US 2 | `westus2` |
| Central US | `centralus` |
| West Europe | `westeu` |
| North Europe | `northeu` |
| UK South | `uksouth` |

**Rules**:
- Use Azure's region name without spaces, lowercase
- Remove hyphens: "east-us-2" becomes "eastus2"
- For full list, run: `az account list-locations --output table`

#### 5. Instance Number (when applicable)

**Purpose**: Distinguish multiple instances of same resource type

**Format**: Three-digit number (001-999)

**Rules**:
- Use only when multiple instances exist
- Start at 001
- Zero-padded to 3 digits
- Sequential numbering

**Examples**:
- First storage account: `001`
- Second storage account: `002`
- First VM in a scale set: `001`

### Separators

**Default**: Hyphen (`-`) between components

**Exceptions**: Resources that don't support hyphens

| Resource Type | Separator | Example |
|---------------|-----------|---------|
| Resource Group | `-` (hyphen) | `rg-myapp-prod-eastus2` |
| Storage Account | None (concatenated) | `stmyappprodeastus2001` |
| Key Vault | `-` (hyphen) | `kv-myapp-prod-eastus2` |
| Virtual Network | `-` (hyphen) | `vnet-myapp-prod-eastus2` |
| Cosmos DB | `-` (hyphen) | `cosmos-myapp-prod-eastus2` |

---

## Resource Type Abbreviations

### Compute

| Resource Type | Abbreviation | Example |
|---------------|--------------|---------|
| Virtual Machine | `vm` | `vm-myapp-prod-eastus2-001` |
| Virtual Machine Scale Set | `vmss` | `vmss-myapp-prod-eastus2` |
| App Service | `app` | `app-myapp-prod-eastus2` |
| Function App | `func` | `func-myapp-prod-eastus2` |
| Container Instance | `aci` | `aci-myapp-prod-eastus2` |
| Kubernetes Service | `aks` | `aks-myapp-prod-eastus2` |

### Storage

| Resource Type | Abbreviation | Example |
|---------------|--------------|---------|
| Storage Account | `st` | `stmyappprodeastus2001` * |
| Blob Container | N/A (child) | `data-backups` (descriptive) |
| File Share | N/A (child) | `shared-documents` |

*Note: Storage accounts must be 3-24 characters, lowercase letters and numbers only, globally unique

### Networking

| Resource Type | Abbreviation | Example |
|---------------|--------------|---------|
| Virtual Network | `vnet` | `vnet-myapp-prod-eastus2` |
| Subnet | `snet` | `snet-web-prod-eastus2` |
| Network Interface | `nic` | `nic-vm001-prod-eastus2` |
| Public IP Address | `pip` | `pip-vm001-prod-eastus2` |
| Load Balancer | `lb` | `lb-myapp-prod-eastus2` |
| Application Gateway | `agw` | `agw-myapp-prod-eastus2` |
| Network Security Group | `nsg` | `nsg-web-prod-eastus2` |
| Route Table | `rt` | `rt-myapp-prod-eastus2` |

### Data & Analytics

| Resource Type | Abbreviation | Example |
|---------------|--------------|---------|
| SQL Database Server | `sql` | `sql-myapp-prod-eastus2` |
| SQL Database | `sqldb` | `sqldb-myapp-prod-eastus2` |
| Cosmos DB Account | `cosmos` | `cosmos-myapp-prod-eastus2` |
| Data Factory | `adf` | `adf-myapp-prod-eastus2` |
| Synapse Workspace | `synapse` | `synapse-myapp-prod-eastus2` |

### Security & Identity

| Resource Type | Abbreviation | Example |
|---------------|--------------|---------|
| Key Vault | `kv` | `kv-myapp-prod-eastus2` |
| Managed Identity | `id` | `id-myapp-prod-eastus2` |

### Management & Governance

| Resource Type | Abbreviation | Example |
|---------------|--------------|---------|
| Resource Group | `rg` | `rg-myapp-prod-eastus2` |
| Management Group | `mg` | `mg-business-unit` |
| Log Analytics Workspace | `log` | `log-myapp-prod-eastus2` |
| Application Insights | `appi` | `appi-myapp-prod-eastus2` |

### Integration

| Resource Type | Abbreviation | Example |
|---------------|--------------|---------|
| Service Bus Namespace | `sb` | `sb-myapp-prod-eastus2` |
| Event Hub Namespace | `evh` | `evh-myapp-prod-eastus2` |
| Event Grid Topic | `evgt` | `evgt-myapp-prod-eastus2` |

---

## Special Cases and Exceptions

### Storage Accounts

**Constraints**:
- 3-24 characters
- Lowercase letters and numbers only
- Must be globally unique
- No hyphens or special characters

**Naming Pattern**:
```
st[workload][environment][region][instance]
```

**Examples**:
- `stmyappprodeastus2001`
- `stdatadevwestus2001`
- `stsharedprodeastus2001`

**Uniqueness Strategy**:
- Add instance numbers: `001`, `002`, etc.
- If still conflicts, add 2-digit suffix: `stmyappprodeastus201`

### Key Vaults

**Constraints**:
- 3-24 characters
- Alphanumeric and hyphens only
- Must start with letter
- Must be globally unique

**Naming Pattern**:
```
kv-[workload]-[environment]-[region]
```

**If duplicate** (globally unique requirement):
- Add instance number: `kv-myapp-prod-eastus2-001`
- Add team/project identifier: `kv-teamname-myapp-prod-eastus2`

### Shared Resources

For resources shared across multiple applications:

**Pattern**:
```
[resource-type]-shared-[environment]-[region]
```

**Examples**:
- `rg-shared-prod-eastus2`
- `kv-shared-prod-eastus2`
- `log-shared-prod-eastus2`

### Global Resources

For resources that are truly global (not region-specific):

**Pattern**:
```
[resource-type]-[workload]-[environment]-global
```

**Examples**:
- `mg-companyname-global` (Management Group)
- `afd-myapp-prod-global` (Azure Front Door)

### Child Resources

Child resources (resources within a parent) can use descriptive names:

| Parent | Child | Naming Approach |
|--------|-------|-----------------|
| Storage Account | Container | Descriptive: `backups`, `logs`, `data` |
| Storage Account | File Share | Descriptive: `shared-files`, `user-profiles` |
| Virtual Network | Subnet | Pattern: `snet-[tier]-[environment]-[region]` |
| SQL Server | Database | Pattern: `sqldb-[purpose]-[environment]` |
| Service Bus | Queue | Descriptive: `orders-queue`, `notifications-queue` |

---

## Environment-Specific Patterns

### Development

**Characteristics**:
- Individual developer environments allowed
- Can include developer initials

**Pattern**:
```
[resource-type]-[workload]-dev-[developer-initials]-[region]
```

**Example**:
- `rg-myapp-dev-jdoe-eastus2` (John Doe's dev environment)
- `st-myapp-dev-jdoe-eastus2001`

### Sandbox

**Characteristics**:
- Temporary learning/experimentation
- Auto-deleted after 7 days
- Cost center tag required

**Pattern**:
```
[resource-type]-sandbox-[purpose]-[region]
```

**Examples**:
- `rg-sandbox-learning-eastus2`
- `rg-sandbox-poc-feature-x-eastus2`

---

## Length Constraints by Resource Type

| Resource Type | Max Length | Min Length | Notes |
|---------------|------------|------------|-------|
| Resource Group | 90 | 1 | Hyphen, underscores, periods, alphanumeric |
| Storage Account | 24 | 3 | Lowercase letters and numbers only |
| Virtual Machine | 64 (Linux), 15 (Windows) | 1 | Consider OS limits |
| Key Vault | 24 | 3 | Alphanumeric and hyphens |
| Virtual Network | 64 | 2 | Alphanumeric, hyphens, underscores, periods |
| SQL Server | 63 | 1 | Lowercase letters, numbers, hyphens |
| App Service | 60 | 2 | Alphanumeric and hyphens |

**When name is too long**:
1. Abbreviate workload name
2. Omit region for shorter code (but inconsistent—avoid if possible)
3. Use instance number instead of full description

---

## Terraform Implementation

### Variables for Name Construction

```hcl
variable "workload" {
  description = "Application or workload name"
  type        = string
  validation {
    condition     = length(var.workload) >= 3 && length(var.workload) <= 12
    error_message = "Workload name must be 3-12 characters."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "test", "stage", "prod", "sandbox"], var.environment)
    error_message = "Environment must be dev, test, stage, prod, or sandbox."
  }
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus2"
}

variable "instance" {
  description = "Instance number for resources that need it"
  type        = string
  default     = "001"
}
```

### Helper Locals

```hcl
locals {
  # Construct resource names using convention
  resource_suffix = "${var.workload}-${var.environment}-${var.location}"

  # Standard names
  resource_group_name  = "rg-${local.resource_suffix}"
  key_vault_name       = "kv-${local.resource_suffix}"
  vnet_name           = "vnet-${local.resource_suffix}"

  # Storage account (no hyphens, max 24 chars)
  storage_account_name = lower(replace(
    "st${var.workload}${var.environment}${var.location}${var.instance}",
    "/[^a-z0-9]/",
    ""
  ))

  # Common tags (see Tagging Standards reference)
  common_tags = {
    Environment = var.environment
    Workload    = var.workload
    ManagedBy   = "terraform"
  }
}
```

### Resource Examples

```hcl
# Resource Group
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = substr(local.storage_account_name, 0, 24)
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.common_tags
}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                = local.key_vault_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  tags                = local.common_tags
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = local.vnet_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = ["10.0.0.0/16"]
  tags                = local.common_tags
}
```

---

## Name Validation Checklist

Before applying Terraform, validate names:

- [ ] Follows standard pattern for resource type
- [ ] Uses approved resource type abbreviation
- [ ] Environment is one of: dev, test, stage, prod, sandbox
- [ ] Region matches actual Azure region code
- [ ] Length is within resource type constraints
- [ ] No invalid characters for resource type
- [ ] Globally unique (for resources requiring it)
- [ ] Consistent with other resources in same workload

---

## Common Mistakes to Avoid

### ❌ Wrong

```hcl
# Inconsistent environment names
resource "azurerm_resource_group" "main" {
  name = "rg-myapp-production-eastus2"  # Should be "prod" not "production"
}

# Wrong separator for storage account
resource "azurerm_storage_account" "main" {
  name = "st-myapp-prod-eastus2-001"  # Hyphens not allowed
}

# Missing components
resource "azurerm_resource_group" "main" {
  name = "myapp-prod"  # Missing resource type and region
}

# Uppercase in storage account
resource "azurerm_storage_account" "main" {
  name = "stMyAppProdEastUS2001"  # Must be lowercase
}
```

### ✅ Correct

```hcl
# Correct environment name
resource "azurerm_resource_group" "main" {
  name = "rg-myapp-prod-eastus2"
}

# Correct storage account (no hyphens)
resource "azurerm_storage_account" "main" {
  name = "stmyappprodeastus2001"
}

# All components present
resource "azurerm_resource_group" "main" {
  name = "rg-myapp-prod-eastus2"
}

# Lowercase storage account
resource "azurerm_storage_account" "main" {
  name = "stmyappprodeastus2001"
}
```

---

## Exceptions and Approvals

**When to request exception**:
- Legacy resources that can't be renamed
- Third-party integrations with naming requirements
- Azure service limitations not covered here

**Exception Process**:
1. Document reason in Terraform code comment
2. Add to `exceptions.md` in repository
3. Get approval from team lead
4. Tag resource with `NamingException = "approved-[date]"`

---

## See Also

**Related References**:
- [Tagging Standards](reference-tagging-standards.md): Required tags for all resources
- [Resource Organization](reference-resource-organization.md): How to group resources

**Concept Documentation**:
- [Understanding Azure Resource Hierarchy](../week1-4/concept-azure-resource-hierarchy.md)

**How-To Guides**:
- [Creating Resources Following Standards](../week1-4/howto-terraform-first-deployment.md)

**External Resources**:
- [Microsoft: Naming Rules and Restrictions](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules)
- [Microsoft: Cloud Adoption Framework - Naming Convention](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
- [Microsoft: Abbreviation Examples](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations)

## Glossary Terms

Terms from the [Glossary](../../config/glossary.yaml):

- **Naming Convention**: Standardized approach to naming resources for consistency and clarity
- **Resource Group**: Logical container for Azure resources
- **Storage Account**: Azure service for storing blobs, files, queues, and tables
- **Virtual Network**: Private network in Azure for resource communication

---

**Document Metadata**:
- **Last Updated**: 2025-12-27
- **Reviewed By**: Cloud Architecture Team
- **Next Review**: 2026-03-27
- **Specification Version**: 2.1
- **Change History**: Updated storage account pattern, added AKS abbreviation
