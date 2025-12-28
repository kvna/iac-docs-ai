---
document_id: concept-terraform-modules
document_type: concept
skill_level: week1-4
topics: [terraform, modules, reusability, best-practices]
technologies: [terraform_v1.5+]
search_keywords:
  - "terraform modules"
  - "reusable infrastructure"
  - "terraform module structure"
  - "module best practices"
  - "local modules"
  - "module sources"
estimated_time: 25
last_reviewed: 2025-12-28
review_status: current
prerequisites:
  - concept-iac-overview
  - howto-environment-setup
learning_outcomes:
  - Understand what Terraform modules are
  - Create and use local modules
  - Apply module best practices
  - Test and version modules
related_documents:
  - learning-path-terraform-fundamentals
  - howto-terraform-state-management
  - reference-naming-conventions
---

# Terraform Modules - Reusable Infrastructure Components

## What are Modules?

Terraform modules are containers for multiple resources that are used together. Think of them as functions in programming - they take inputs, perform operations, and return outputs.

Instead of writing the same Terraform code repeatedly, you create a module once and reuse it across projects.

## Why Use Modules?

**Benefits:**
- **Reusability**: Write once, use everywhere
- **Consistency**: Same configuration across environments
- **Maintainability**: Update in one place, affects all uses
- **Abstraction**: Hide complexity, expose simple interface
- **Testing**: Test modules independently

**Example scenario:**
You need to create resource groups in 5 different projects. Without modules, you copy-paste code 5 times. With modules, you create one resource group module and call it 5 times with different parameters.

## Module Structure

A typical module directory:

```
modules/
└── resource-group/
    ├── main.tf          # Main resource definitions
    ├── variables.tf     # Input variables
    ├── outputs.tf       # Output values
    └── README.md        # Documentation
```

**Example module** (`modules/resource-group/main.tf`):
```hcl
resource "azurerm_resource_group" "this" {
  name     = var.name
  location = var.location
  tags     = var.tags
}
```

**Variables** (`modules/resource-group/variables.tf`):
```hcl
variable "name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "northeurope"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
```

**Outputs** (`modules/resource-group/outputs.tf`):
```hcl
output "id" {
  description = "Resource group ID"
  value       = azurerm_resource_group.this.id
}

output "name" {
  description = "Resource group name"
  value       = azurerm_resource_group.this.name
}
```

## Using Modules

Call a module in your main Terraform code:

```hcl
module "dev_rg" {
  source   = "../../modules/resource-group"
  name     = "rg-myapp-dev-northeu"
  location = "northeurope"
  tags = {
    Environment = "Development"
    CostCenter  = "IT"
  }
}

module "prod_rg" {
  source   = "../../modules/resource-group"
  name     = "rg-myapp-prod-northeu"
  location = "northeurope"
  tags = {
    Environment = "Production"
    CostCenter  = "IT"
  }
}

# Access module outputs
output "dev_rg_id" {
  value = module.dev_rg.id
}
```

## Module Sources

Modules can be loaded from different locations:

**Local paths:**
```hcl
module "example" {
  source = "../../modules/my-module"
}
```

**Git repositories:**
```hcl
module "example" {
  source = "git::https://github.com/company/terraform-modules.git//modules/network?ref=v1.0.0"
}
```

**Terraform Registry:**
```hcl
module "example" {
  source  = "Azure/network/azurerm"
  version = "5.3.0"
}
```

## Best Practices

1. **Keep modules focused**: One module = one responsibility
2. **Use variables for flexibility**: Don't hardcode values
3. **Provide sensible defaults**: Make modules easy to use
4. **Document thoroughly**: README with examples
5. **Version your modules**: Use Git tags (v1.0.0, v1.1.0)
6. **Test modules**: Create example implementations
7. **Use outputs wisely**: Expose useful values for composition

## Common Module Patterns

### Pattern 1: Simple Resource Module
Wraps a single resource type with common configurations.

### Pattern 2: Composite Module
Combines multiple related resources (e.g., network module with VNet + subnets + NSG).

### Pattern 3: Environment Module
Complete environment in a module (dev/test/prod with all resources).

## Example: Network Module

Here's a more complete example:

```hcl
# modules/network/main.tf
resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = var.tags
}

resource "azurerm_subnet" "subnets" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value]
}

# modules/network/variables.tf
variable "vnet_name" {
  description = "Virtual network name"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "address_space" {
  description = "VNet address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnets" {
  description = "Map of subnet names to CIDR blocks"
  type        = map(string)
  default     = {
    "subnet1" = "10.0.1.0/24"
    "subnet2" = "10.0.2.0/24"
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}

# modules/network/outputs.tf
output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "subnet_ids" {
  value = { for k, v in azurerm_subnet.subnets : k => v.id }
}
```

**Usage:**
```hcl
module "network" {
  source = "../../modules/network"

  vnet_name           = "vnet-myapp-prod"
  resource_group_name = "rg-myapp-prod"
  location            = "northeurope"
  address_space       = ["10.0.0.0/16"]

  subnets = {
    "app"     = "10.0.1.0/24"
    "data"    = "10.0.2.0/24"
    "gateway" = "10.0.3.0/27"
  }

  tags = {
    Environment = "Production"
  }
}

# Use the outputs
output "app_subnet_id" {
  value = module.network.subnet_ids["app"]
}
```

## Testing Modules

Create a `test` or `examples` directory:

```
modules/network/
├── main.tf
├── variables.tf
├── outputs.tf
├── README.md
└── examples/
    └── basic/
        ├── main.tf
        └── README.md
```

Test the module:
```bash
cd modules/network/examples/basic
terraform init
terraform plan
terraform apply
# Verify it works
terraform destroy
```

## Troubleshooting

**Problem**: "Module not found"
- Check the `source` path is correct
- Run `terraform init` after adding/modifying module source

**Problem**: "Invalid value for variable"
- Check variable types match
- Ensure required variables are provided
- Review module's `variables.tf` for requirements

**Problem**: Changes to module not reflected
- Run `terraform get -update` to fetch latest module code
- Check if you need to run `terraform init -upgrade`

## Summary

Modules enable:
- ✅ Code reusability
- ✅ Consistency across projects
- ✅ Easier maintenance
- ✅ Better organization

Start simple with local modules, then progress to shared module repositories as your needs grow.

**Next Steps:**
- Create your first simple module
- Build a library of common modules for your team
- Explore the Terraform Registry for community modules
