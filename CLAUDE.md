# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**IaC Documentation Modernization & AI Search POC** - A comprehensive solution for IaC team documentation with AI-powered natural language search capabilities. This project combines:

1. **Structured Documentation System**: Progressive learning framework (Day 1 → 12 months)
2. **AI-Powered Search**: Natural language search using Azure AI Search + OpenAI
3. **Quality Automation**: Automated validation of documentation standards
4. **Complete IaC**: Full Terraform infrastructure for POC deployment to Azure

## Architecture

### Three-Layer System

```
┌─────────────────────────────────────────────────────────┐
│ 1. DOCUMENTATION LAYER                                   │
│    - Markdown docs organized by skill level             │
│    - 5 doc types: Concept, How-To, Reference,           │
│      Troubleshooting, Learning Paths                    │
│    - Centralized glossary (config/glossary.yaml)        │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│ 2. AUTOMATION LAYER (PowerShell Scripts)                │
│    - Deployment: Deploy-IaCDocsPOC.ps1                  │
│    - Validation: Test-DocumentQuality.ps1               │
│    - Web Deploy: Deploy-Web.ps1                         │
│    - Indexing: Index-Documents.ps1                      │
│    - Cleanup: Destroy-IaCDocsPOC.ps1                    │
│    - Prerequisites: Test-Prerequisites.ps1              │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│ 3. INFRASTRUCTURE LAYER (Terraform Modules)             │
│    - Azure AI Search (semantic + vector search)         │
│    - Azure OpenAI (embeddings + GPT)                    │
│    - Storage Account (document storage)                 │
│    - Function App (API endpoints - Python)              │
│    - Static Web App (frontend UI)                       │
│    - Monitoring (App Insights, Key Vault)               │
└─────────────────────────────────────────────────────────┘
```

### Key Architectural Patterns

#### Terraform Module Structure

The infrastructure uses a **modular Terraform architecture**:

- **environments/poc/** - Main deployment configuration with locals for naming conventions
- **modules/storage/** - Blob storage for documents
- **modules/search/** - Azure AI Search service with semantic ranking
- **modules/openai/** - Azure OpenAI for embeddings (ada-002) and query enhancement (gpt-4o-mini)
- **modules/function-app/** - Azure Functions API (Linux-based)
- **modules/monitoring/** - App Insights and Log Analytics

**Resource Naming Convention**: All resources follow `{resource-type}-{workload}-{environment}-{region-code}`
- Defined in terraform/environments/poc/main.tf (lines 42-73)
- Use locals (local.storage_name, local.search_name) - never hardcode

**Web Resources** (terraform/environments/poc/web.tf):
- Static Web App for frontend (Free tier)
- Linux Function App with Python 3.11 runtime
- Separate storage account for Function App
- CORS automatically configured for local dev + production
- **Important**: Function App uses West Europe due to quota limitations in North Europe

#### Search & AI Integration Flow

1. **Document Indexing** (scripts/deployment/Index-Documents.ps1):
   - Reads markdown files with YAML frontmatter
   - Generates embeddings using Azure OpenAI (text-embedding-ada-002)
   - Stores in Azure AI Search with vector fields

2. **Query Processing** (web/api/ask/__init__.py):
   - User question → Generate embedding
   - Hybrid search (vector + keyword) against Azure AI Search
   - Retrieve top 3 relevant documents
   - Construct context from document content
   - GPT-4 generates answer from context only
   - Returns answer + source attribution

**Critical**: Search responses MUST cite sources. The API returns both answer and sources array with document metadata.

#### Documentation System Design

**Progressive Disclosure Model**: Content organized by skill level (day1 → week1-4 → month1-2 → month3-6 → month6-12 → expert)

**Five Document Types**:
1. **Concept** - Explain "what" and "why" (templates/concept-template.md)
2. **How-To** - Step-by-step task instructions (templates/howto-template.md)
3. **Reference** - Lookup information and specifications (templates/reference-template.md)
4. **Troubleshooting** - Problem-solution patterns (templates/troubleshooting-template.md)
5. **Learning Paths** - Curated document sequences (templates/learning-path-template.md)

**Single Source of Truth**: `config/glossary.yaml` contains canonical definitions for all terminology. Documents reference this glossary via `glossary_terms` metadata field.

**Metadata-Driven**: Every document has comprehensive YAML frontmatter for:
- AI search optimization (search_keywords, natural language phrases)
- Navigation (prerequisites, related_documents)
- Quality tracking (last_reviewed, review_status)
- Learning paths (skill_level, learning_outcomes)

## Common Development Commands

### Quick Start

```powershell
# Fully automated deployment
pwsh ./Quick-Start.ps1

# Check prerequisites before deployment
pwsh ./scripts/deployment/Test-Prerequisites.ps1
```

### Infrastructure Deployment

```powershell
# Deploy infrastructure with free tier (default)
pwsh ./scripts/deployment/Deploy-IaCDocsPOC.ps1

# Deploy with basic tier
pwsh ./scripts/deployment/Deploy-IaCDocsPOC.ps1 -SearchSku basic

# Plan only (no deployment)
pwsh ./scripts/deployment/Deploy-IaCDocsPOC.ps1 -PlanOnly

# Destroy all infrastructure
pwsh ./scripts/deployment/Destroy-IaCDocsPOC.ps1
```

### Web Application Deployment

**After infrastructure is deployed**, deploy the web components:

```powershell
# Deploy Function App backend
pwsh ./scripts/deployment/Deploy-Web.ps1 -DeployBackend

# Deploy Static Web App frontend
pwsh ./scripts/deployment/Deploy-Web.ps1 -DeployFrontend

# Deploy both
pwsh ./scripts/deployment/Deploy-Web.ps1 -DeployFrontend -DeployBackend
```

### Document Indexing

```powershell
# Index all documents in Azure AI Search
pwsh ./scripts/deployment/Index-Documents.ps1

# Index limited number of documents (testing)
pwsh ./scripts/deployment/Index-Documents.ps1 -MaxDocuments 5

# Query the search index
pwsh ./scripts/deployment/Search-Documents.ps1 -Query "terraform state"

# Test AI-powered Q&A
pwsh ./scripts/deployment/Ask-Documentation.ps1 -Question "How do I install Terraform?"
```

### Local Development (Web Interface)

```bash
# 1. Start Function App locally
cd web/api
cp local.settings.json.template local.settings.json
# Edit local.settings.json with your Azure resource values
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt
func start
# API runs at http://localhost:7071/api/ask

# 2. Serve frontend (in separate terminal)
cd web/frontend
python -m http.server 8000
# Or: npx http-server -p 8000
# Open http://localhost:8000
```

**Testing Function App locally**:
```bash
curl -X POST http://localhost:7071/api/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "How do I install Terraform?"}'
```

### Terraform (Manual)

```bash
# Initialize and deploy
cd terraform/environments/poc
terraform init
terraform plan
terraform apply

# Get outputs
terraform output

# Destroy
terraform destroy
```

### Documentation Validation

```powershell
# Validate single document
pwsh ./scripts/validation/Test-DocumentQuality.ps1 -Path "./docs/day1/concept-iac-overview.md"

# Validate all documentation
pwsh ./scripts/validation/Test-DocumentQuality.ps1 -Path "./docs"

# Validate with minimum score requirement
pwsh ./scripts/validation/Test-DocumentQuality.ps1 -Path "./docs" -MinScore 85

# Include searchability testing (requires deployed infrastructure)
pwsh ./scripts/validation/Test-DocumentQuality.ps1 -Path "./docs/day1/concept-iac-overview.md" -TestSearch
```

### Azure Authentication

```bash
# Azure authentication (required before deployment)
az login
az account set --subscription "Your-Subscription-Name"

# Verify authentication
az account show
```

## Creating New Documentation

**Always use templates** from `templates/` directory. Never create documentation from scratch.

### Step-by-Step Process

1. **Choose document type** based on purpose:
   - Explaining concept? → concept-template.md
   - Teaching task? → howto-template.md
   - Providing reference? → reference-template.md
   - Solving problem? → troubleshooting-template.md
   - Creating learning sequence? → learning-path-template.md

2. **Copy template to appropriate skill-level directory**:
   ```bash
   cp templates/concept-template.md docs/day1/concept-your-topic.md
   ```

3. **Fill ALL metadata fields** (required for validation):
   - document_id: Must be unique, format `[type]-[descriptive-slug]`
   - search_keywords: 5-10 natural language phrases users search for
   - glossary_terms: Reference terms from config/glossary.yaml
   - prerequisites: List document_ids that should be read first
   - learning_outcomes: Specific, measurable outcomes

4. **Write content following template structure** - Keep all template sections

5. **Validate before committing**:
   ```powershell
   pwsh ./scripts/validation/Test-DocumentQuality.ps1 -Path "docs/your-doc.md"
   ```
   Must achieve 80/100 minimum score and pass metadata validation

6. **Update glossary** if introducing new terms:
   - Add to config/glossary.yaml following existing structure
   - Include: term, full_name, definition, category, first_appears, related_terms, search_keywords

## Key Configuration Files

### Glossary (config/glossary.yaml)
- **Single source of truth** for all terminology
- YAML structure with: term, full_name, definition, category, related_terms, search_keywords
- **Never duplicate definitions** - always reference glossary from docs

### Terraform Variables (terraform/environments/poc/variables.tf)
- Location/region configuration
- SKU selections (search_sku, function_sku)
- Cost center and owner tags
- Network and security settings

### Terraform State
- Currently uses **local state** (default)
- Backend configuration commented out in main.tf (lines 15-23)
- To enable remote state: Uncomment backend block and configure Azure Storage

### Function App Configuration (web/api/local.settings.json.template)
Environment variables needed for local Function App development:
- `SEARCH_ENDPOINT` - Azure AI Search endpoint
- `SEARCH_KEY` - Search service admin key
- `SEARCH_INDEX` - Search index name (default: "docs-index")
- `OPENAI_ENDPOINT` - Azure OpenAI endpoint
- `OPENAI_KEY` - OpenAI API key
- `OPENAI_DEPLOYMENT` - GPT deployment name (default: "gpt-4")
- `EMBEDDING_DEPLOYMENT` - Embedding deployment name (default: "text-embedding-ada-002")

## Important Patterns

### Document Metadata Pattern
Every markdown file MUST start with complete YAML frontmatter. Example structure:
```yaml
---
document_id: concept-unique-id
document_type: concept
skill_level: day1
topics: [terraform, azure]
technologies: [terraform_v1.5+, azure_cli_2.50+]
prerequisites: ["Azure subscription access"]
learning_outcomes:
  - "Understand the purpose of X"
search_keywords:
  - "what is X"
  - "how to use X"
related_documents:
  - howto-related-task
glossary_terms:
  - terraform
  - azure
last_reviewed: 2025-12-27
review_status: current
estimated_time: 15
---
```

### Resource Naming Pattern
All Azure resources follow convention in terraform/environments/poc/main.tf (lines 42-73):
```
{resource-type-prefix}-{workload}-{environment}-{region-code}
Example: search-iac-docs-poc-northeu
```

Use locals in main.tf for consistency - never hardcode resource names.

### Module Invocation Pattern
Modules are called from environments/poc/main.tf with:
- source = relative path to module
- Explicitly pass resource_group_name, location, tags
- Use locals for naming (local.storage_name, local.search_name)

### Function App API Pattern
The Python Function App (web/api/ask/__init__.py) follows this flow:
1. Validate environment variables on startup
2. Handle CORS preflight (OPTIONS)
3. Parse and validate request JSON
4. Generate embedding for user question using Azure OpenAI
5. Perform hybrid search (vector + text) against Azure AI Search
6. Retrieve top 3 documents
7. Construct GPT prompt with document context
8. Generate answer using GPT-4 (temperature: 0.3, max_tokens: 2000)
9. Return JSON with answer + sources array

**Error handling**: All errors return JSON with `{"error": "message", "detail": "..."}` and appropriate HTTP status codes.

### Quality Validation Pattern
Test-DocumentQuality.ps1 validates:
1. **Metadata completeness** (Pass/Fail - required)
2. **Readability** (0-100, target 80+)
3. **Code block validity** (syntax checking)
4. **Link integrity** (internal + external)
5. **Searchability** (0-100, target 80+)

Overall score is weighted average. Minimum 80/100 to publish.

## Deployment Workflow

### Complete Deployment Sequence

1. **Prerequisites Check**:
   ```powershell
   pwsh ./scripts/deployment/Test-Prerequisites.ps1
   ```

2. **Deploy Infrastructure**:
   ```powershell
   pwsh ./scripts/deployment/Deploy-IaCDocsPOC.ps1
   ```
   Creates: Resource Group, Storage, AI Search, OpenAI, Function App, Static Web App, Monitoring

3. **Deploy Function App Code**:
   ```powershell
   pwsh ./scripts/deployment/Deploy-Web.ps1 -DeployBackend
   ```
   Or manually:
   ```bash
   cd web/api
   func azure functionapp publish func-iac-docs-poc-northeu --python
   ```

4. **Index Documents**:
   ```powershell
   pwsh ./scripts/deployment/Index-Documents.ps1
   ```
   Generates embeddings and populates search index

5. **Deploy Frontend** (optional - Static Web App):
   ```powershell
   pwsh ./scripts/deployment/Deploy-Web.ps1 -DeployFrontend
   ```
   Or manually:
   ```bash
   cd web/frontend
   npm install -g @azure/static-web-apps-cli
   # Get deployment token from Azure Portal or Terraform output
   swa deploy --app-location . --deployment-token $SWA_TOKEN
   ```

6. **Test**:
   ```powershell
   pwsh ./scripts/deployment/Test-Search.ps1
   pwsh ./scripts/deployment/Ask-Documentation.ps1 -Question "What is IaC?"
   ```

### Teardown Sequence

```powershell
# Option 1: Full destroy (infrastructure + data)
pwsh ./scripts/deployment/Destroy-IaCDocsPOC.ps1

# Option 2: Complete teardown with confirmation
pwsh ./scripts/deployment/Teardown-All.ps1
```

## Cost Management

### Default Deployment (Free Tier)
- AI Search: Free tier ($0)
- Azure OpenAI: S0 pay-per-use (~$10/month)
- Storage: Standard LRS (~$1/month)
- Function App: Consumption (free tier)
- Static Web App: Free tier
- **Total: ~$12/month**

### Cleanup
**IMPORTANT**: Run destroy script to stop all costs:
```powershell
pwsh ./scripts/deployment/Destroy-IaCDocsPOC.ps1
```

## Dependencies and Prerequisites

Required tools (checked by Test-Prerequisites.ps1):
- **PowerShell 7.4+** (all scripts require pwsh)
- **Terraform 1.5+** (infrastructure deployment)
- **Azure CLI 2.50+** (authentication and Azure operations)
- **Python 3.11+** (Function App runtime)
- **Azure Functions Core Tools v4** (local Function App testing)
- **Node.js 18+** (Static Web App CLI - optional)
- **Azure subscription** with Owner/Contributor access
- **Azure OpenAI access** (may require application at https://aka.ms/oai/access)

## File Organization

```
.
├── config/
│   └── glossary.yaml              # Canonical term definitions
├── docs/                          # Documentation by skill level
│   ├── day1/                      # First-day content
│   ├── week1-4/                   # Foundation building
│   ├── month1-2/                  # Intermediate
│   ├── month3-6/                  # Advanced
│   ├── month6-12/                 # Expert
│   ├── reference/                 # Reference documentation
│   ├── troubleshooting/           # Problem-solution guides
│   └── learning-paths/            # Curated sequences
├── templates/                     # Document templates (ALWAYS use these)
├── terraform/
│   ├── environments/poc/          # Main deployment config
│   │   ├── main.tf               # Core infrastructure
│   │   ├── web.tf                # Static Web App + Function App
│   │   └── variables.tf          # Configuration variables
│   └── modules/                   # Reusable infrastructure modules
│       ├── storage/
│       ├── search/
│       ├── openai/
│       ├── function-app/
│       └── monitoring/
├── scripts/
│   ├── deployment/                # Deploy/destroy/index scripts
│   ├── validation/                # Quality validation
│   └── quality/                   # Quality assessment
└── web/                           # Web application
    ├── api/                       # Function App (Python)
    │   ├── ask/__init__.py       # Main API logic
    │   ├── requirements.txt      # Python dependencies
    │   └── local.settings.json.template
    └── frontend/                  # Static Web App (HTML/CSS/JS)
        ├── index.html
        ├── app.js
        ├── styles.css
        └── staticwebapp.config.json
```

## Documentation Review Process

**Every 90 days**: Documents require review
- Update `last_reviewed` date in metadata
- Set `review_status` to one of: current, needs_review, deprecated
- Check technical accuracy, version compatibility, link integrity

**Deprecation**: Set review_status to "deprecated" and add warning banner at top of document

## Special Considerations

### When Modifying Terraform
1. **Test with `terraform plan`** before applying
2. **Update module outputs** if adding new resources
3. **Maintain naming convention** using locals
4. **Update cost estimates** in README.md if SKUs change
5. **Consider regional limitations**: Function Apps may need West Europe due to quota

### When Modifying Function App
1. **Update requirements.txt** for new Python dependencies
2. **Test locally first** using `func start`
3. **Maintain CORS configuration** for both local dev and production
4. **Update environment variables** in both local.settings.json and Terraform (web.tf)
5. **Preserve source attribution** in responses (answer + sources array)

### When Adding New Document Types
1. **Create new template** in templates/
2. **Update DOCUMENTATION_SYSTEM_GUIDE.md** with type definition
3. **Update validation script** if new metadata fields needed

### When Working with Glossary
- **Never modify definitions in documents** - only in glossary.yaml
- **Validate all glossary_terms references** point to existing terms
- **Add related_terms** to create knowledge graph connections

## Testing and Validation

### Before Committing Documentation
1. Run validation script and achieve 80+ score
2. Test all code examples if present
3. Verify all internal links point to existing documents
4. Confirm all glossary_terms exist in glossary.yaml

### Before Deploying Infrastructure
1. Run Test-Prerequisites.ps1 to verify environment
2. Review terraform plan output carefully
3. Verify Azure OpenAI access for your subscription
4. Confirm cost estimates align with budget

### Testing Function App
```bash
# Local testing
curl -X POST http://localhost:7071/api/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "How do I install Terraform?"}'

# Production testing
curl -X POST https://func-iac-docs-poc-northeu.azurewebsites.net/api/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "How do I install Terraform?"}'
```

Expected response format:
```json
{
  "answer": "To install Terraform...",
  "sources": [
    {
      "document_id": "howto-environment-setup",
      "title": "How to Set Up Your Environment",
      "document_type": "howto",
      "file_path": "day1/howto-environment-setup.md"
    }
  ],
  "question": "How do I install Terraform?"
}
```

## Search Optimization for AI

Documents are optimized for RAG (Retrieval Augmented Generation):

1. **Natural language search_keywords**: Include questions users actually ask
   - "how do I deploy terraform"
   - "what is infrastructure as code"
   - "fix state lock error"

2. **Semantic richness**: Use varied terminology (official + colloquial + acronyms)

3. **Context in headings**: Make headings meaningful without surrounding context

4. **Standalone sections**: Each section should be understandable independently (for chunking)

5. **Question formats**: Include "What is...", "How do I...", "Why does...", "How to fix..."

## Troubleshooting

### Common Issues

**"Failed to fetch" in web UI**:
- Check Function App is running (local: `func start`, production: Azure Portal)
- Verify CORS settings in web.tf or Function App configuration
- Check browser console for specific errors

**Function App deployment fails**:
- Ensure Python 3.11 is available
- Verify all dependencies in requirements.txt are compatible
- Check Function App SKU supports Linux (Y1, B1, S1)

**Document indexing fails**:
- Verify Azure OpenAI deployment names match configuration
- Check embedding deployment is "text-embedding-ada-002"
- Ensure Search Index exists (created automatically by Index-Documents.ps1)

**Search returns no results**:
- Verify documents have been indexed (pwsh ./scripts/deployment/Index-Documents.ps1)
- Check index name matches in Function App settings (SEARCH_INDEX)
- Test direct search: pwsh ./scripts/deployment/Search-Documents.ps1 -Query "test"

**Terraform state lock errors**:
- Currently using local state (no remote locking)
- If using remote backend, check storage account accessibility
- Remove .terraform.lock.hcl and re-run terraform init if providers are updated
