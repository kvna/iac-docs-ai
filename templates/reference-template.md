---
document_id: reference-[short-descriptive-id]
document_type: reference
skill_level: [day1|week1-4|month1-2|month3-6|month6-12|expert]
topics: [list, of, topics]
technologies: [terraform_v1.5+, azure_cli_2.50+, powershell_7.4+, azuredevops]
prerequisites:
  - [document_id_of_prerequisite_1]
learning_outcomes:
  - [What can be looked up in this reference]
  - [Another lookup capability]
estimated_time: [minutes - typically shorter for lookups]
last_reviewed: [YYYY-MM-DD]
review_status: [current|needs_review|deprecated]
search_keywords:
  - "[specific term or command]"
  - "[technical specification]"
  - "[parameter reference]"
  - "[syntax reference]"
related_documents:
  - [related_document_id_1]
  - [related_document_id_2]
glossary_terms:
  - [term_from_glossary]
reference_type: [command|configuration|standard|api|specification]
---

# [Reference Title]

## Purpose

This reference provides [type of information] for [subject]. Use this document to look up [specific use cases for this reference].

**When to use this reference**:
- When you need to [use case 1]
- When looking for [use case 2]
- When verifying [use case 3]

## Quick Reference

| Item | Description | Example/Value |
|------|-------------|---------------|
| [Key item 1] | [Brief description] | `[example]` |
| [Key item 2] | [Brief description] | `[example]` |
| [Key item 3] | [Brief description] | `[example]` |

## Detailed Specification

### [Section 1: Primary Topic]

#### Overview
[Brief introduction to this section]

#### Syntax

```
[Formal syntax notation]
[command/configuration] [required-parameter] [optional-parameter]
```

**Components**:
- `[required-parameter]`: Description and valid values
- `[optional-parameter]`: Description and valid values
- `[flags]`: Description of available flags

#### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `parameter1` | string | Yes | - | Detailed description of parameter |
| `parameter2` | number | No | `0` | What this parameter controls |
| `parameter3` | boolean | No | `false` | When to use this parameter |

#### Examples

**Basic Example**:
```hcl
# Minimal required configuration
[code example with minimal parameters]
```

**Advanced Example**:
```hcl
# Full configuration with optional parameters
[code example with all parameters shown]
```

**Real-World Example**:
```hcl
# Production-grade configuration
[practical example with common patterns]
```

---

### [Section 2: Secondary Topic]

#### Overview
[Description of this section]

#### Specification Table

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `field1` | string | Max 64 chars, lowercase | [Purpose] |
| `field2` | integer | 1-100 | [Purpose] |
| `field3` | enum | [value1, value2, value3] | [Purpose] |

#### Valid Values

**[Field Name]**:
- `value1`: [When to use, implications]
- `value2`: [When to use, implications]
- `value3`: [When to use, implications]

#### Usage Examples

**Scenario 1: [Common Use Case]**
```
[Example code]
```
**Output/Result**: [Expected outcome]

**Scenario 2: [Another Use Case]**
```
[Example code]
```
**Output/Result**: [Expected outcome]

---

### [Section 3: Configuration Options]

#### Standard Configuration

```hcl
# Recommended standard configuration
[configuration block]
```

**Configuration breakdown**:
- **Line 1-3**: [Explanation]
- **Line 4-6**: [Explanation]
- **Line 7-9**: [Explanation]

#### Environment-Specific Configurations

**Development Environment**:
```hcl
[dev configuration]
```

**Testing Environment**:
```hcl
[test configuration]
```

**Production Environment**:
```hcl
[prod configuration]
```

#### Advanced Options

| Option | Purpose | Risk Level | Recommendation |
|--------|---------|------------|----------------|
| `advanced_option1` | [Purpose] | Low | [When to use] |
| `advanced_option2` | [Purpose] | Medium | [Caution] |
| `advanced_option3` | [Purpose] | High | [Expert only] |

---

## Command Reference

### [Command Category 1]

#### `command-name`

**Purpose**: [What this command does]

**Syntax**:
```bash
command-name [options] <required-arg> [optional-arg]
```

**Arguments**:
- `<required-arg>`: [Description]
- `[optional-arg]`: [Description]

**Options**:
| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--option1` | `-o` | [Description] | [Default] |
| `--option2` | `-f` | [Description] | [Default] |
| `--verbose` | `-v` | Increase output detail | `false` |

**Exit Codes**:
- `0`: Success
- `1`: General error
- `2`: [Specific error condition]

**Examples**:
```bash
# Basic usage
command-name basic-arg

# With options
command-name --option1 value1 --option2 required-arg

# Complex example
command-name --verbose --option1 value1 optional-arg
```

**Output**:
```
[Example output format]
```

---

### [Command Category 2]

[Follow same structure as Command Category 1]

---

## Standards and Conventions

### Naming Standards

#### Resource Naming Convention

**Pattern**: `[prefix]-[name]-[environment]-[region]-[instance]`

**Components**:
| Component | Description | Valid Values | Example |
|-----------|-------------|--------------|---------|
| prefix | Resource type abbreviation | See table below | `rg`, `st`, `kv` |
| name | Descriptive name | alphanumeric, hyphen | `myapp`, `shared-services` |
| environment | Environment indicator | `dev`, `test`, `staging`, `prod` | `prod` |
| region | Azure region abbreviation | See region codes | `eastus2`, `westeu` |
| instance | Instance number (if multiple) | 001-999 | `001` |

**Resource Type Abbreviations**:
| Resource Type | Abbreviation | Example |
|---------------|--------------|---------|
| Resource Group | `rg` | `rg-myapp-prod-eastus2` |
| Storage Account | `st` | `stmyappprodeastus2001` |
| Key Vault | `kv` | `kv-myapp-prod-eastus2` |
| Virtual Network | `vnet` | `vnet-myapp-prod-eastus2` |

### Tagging Standards

**Required Tags** (All Resources):
```hcl
tags = {
  Environment  = "prod"              # dev, test, staging, prod
  Owner        = "team-name"         # Team or individual responsible
  CostCenter   = "CC-12345"          # Cost center for billing
  Application  = "application-name"  # Application identifier
  ManagedBy    = "terraform"         # How resource is managed
}
```

**Optional Tags**:
```hcl
tags = {
  Project      = "project-name"
  Department   = "department-name"
  Criticality  = "high"              # high, medium, low
  DataClass    = "confidential"      # public, internal, confidential, restricted
  ComplianceCategory = "pci"         # pci, hipaa, sox, etc.
}
```

---

## API Reference

### [API Name]

**Base URL**: `https://api.example.com/v1`

**Authentication**: [Auth method]

#### Endpoints

##### GET /[resource]

**Description**: [What this endpoint does]

**Request**:
```http
GET /resource/{id} HTTP/1.1
Host: api.example.com
Authorization: Bearer {token}
```

**Parameters**:
| Parameter | Type | Location | Required | Description |
|-----------|------|----------|----------|-------------|
| `id` | string | path | Yes | Resource identifier |
| `filter` | string | query | No | Filter results |

**Response** (200 OK):
```json
{
  "id": "12345",
  "name": "example",
  "status": "active",
  "created": "2025-01-01T00:00:00Z"
}
```

**Error Responses**:
- `400 Bad Request`: [Cause]
- `401 Unauthorized`: [Cause]
- `404 Not Found`: [Cause]
- `500 Internal Server Error`: [Cause]

---

## Version Compatibility

### Supported Versions

| Component | Minimum Version | Recommended Version | Notes |
|-----------|----------------|---------------------|-------|
| Terraform | 1.5.0 | 1.6.x | [Specific notes] |
| Azure CLI | 2.50.0 | 2.55.x | [Specific notes] |
| PowerShell | 7.4.0 | 7.4.x | [Specific notes] |
| azurerm Provider | 3.80.0 | 3.85.x | [Specific notes] |

### Version-Specific Behavior

**Terraform 1.5.x**:
- [Feature or behavior specific to this version]
- [Breaking change or deprecation]

**Terraform 1.6.x**:
- [New features]
- [Changes from 1.5.x]

---

## Limits and Quotas

### Azure Resource Limits

| Resource | Limit per Subscription | Limit per Resource Group | Notes |
|----------|------------------------|--------------------------|-------|
| Resource Groups | 980 | N/A | [Additional context] |
| Storage Accounts | 250 | [Limit] | [Soft/Hard limit info] |
| Virtual Networks | 1,000 | [Limit] | [Regional variations] |

**Source**: [Microsoft Documentation Link]
**Last Updated**: [Date]

### Service Limits

| Service | Metric | Limit | Upgrade Options |
|---------|--------|-------|-----------------|
| [Service] | [Metric] | [Limit] | [How to increase] |

---

## Configuration Schema

### JSON Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["field1", "field2"],
  "properties": {
    "field1": {
      "type": "string",
      "description": "Description of field1",
      "pattern": "^[a-z0-9-]+$"
    },
    "field2": {
      "type": "integer",
      "description": "Description of field2",
      "minimum": 1,
      "maximum": 100
    }
  }
}
```

### YAML Schema Example

```yaml
# Valid configuration structure
field1: "value"       # string - required
field2: 42            # integer - required
field3:               # object - optional
  nested1: "value"
  nested2: true
```

---

## Error Codes

| Code | Message | Cause | Resolution |
|------|---------|-------|------------|
| `ERR001` | [Error message] | [What causes this] | [How to fix] |
| `ERR002` | [Error message] | [What causes this] | [How to fix] |
| `ERR003` | [Error message] | [What causes this] | [How to fix] |

---

## Best Practices

### Performance

- **Practice 1**: [Description and rationale]
- **Practice 2**: [Description and rationale]
- **Practice 3**: [Description and rationale]

### Security

- **Practice 1**: [Security consideration]
- **Practice 2**: [Security consideration]
- **Practice 3**: [Security consideration]

### Cost Optimization

- **Practice 1**: [Cost-saving approach]
- **Practice 2**: [Cost-saving approach]
- **Practice 3**: [Cost-saving approach]

---

## See Also

**Related References**:
- [Reference Doc 1]: [Relationship to this doc]
- [Reference Doc 2]: [How they complement each other]

**Concept Documentation**:
- [Concept Doc]: Understanding the principles behind this reference

**How-To Guides**:
- [How-To Guide]: Practical application of this reference material

**External Resources**:
- [Official Documentation]: [URL]
- [API Reference]: [URL]
- [Specification]: [URL]

## Glossary Terms

Terms from the [Glossary](../config/glossary.yaml):

- **[term_1]**: [Quick reference note]
- **[term_2]**: [Quick reference note]

---

**Document Metadata**:
- **Last Updated**: [YYYY-MM-DD]
- **Reviewed By**: [Name/Team]
- **Next Review**: [YYYY-MM-DD]
- **Specification Version**: [Version if applicable]
- **Change History**: [Link]
