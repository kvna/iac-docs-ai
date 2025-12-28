# POC Usage Guide

## System Overview

The POC deployment includes a fully functional AI-powered documentation search system with the following components:

### Deployed Infrastructure
- **Azure AI Search** (Free tier) - Search index with vector and keyword search capabilities
- **Azure OpenAI** (S0 tier) - text-embedding-ada-002 and gpt-4o-mini deployments
- **Azure Storage** - Blob storage for documents
- **Azure Key Vault** - Secrets management
- **Azure Log Analytics** - Monitoring and logging
- **Azure Application Insights** - Application telemetry

**Total Cost**: ~$25-35/month

### Application Scripts
- `Ask-Documentation.ps1` - **AI chat interface (ChatGPT-like Q&A)**
- `Search-Documents.ps1` - Search interface with vector/keyword/hybrid modes
- `Create-SearchIndex.ps1` - Creates the Azure AI Search index with schema
- `Index-Documents.ps1` - Indexes markdown docs with OpenAI embeddings
- `Upload-Documents.ps1` - Uploads docs to Azure Blob Storage
- `Test-Search.ps1` - Quick validation test
- `Teardown-All.ps1` - **Destroys all resources (stops costs)**
- `Restore-All.ps1` - **Recreates everything in one command**

## Teardown & Restore (Cost Management)

### Stop All Costs (Teardown)

When you're done using the system and want to stop Azure charges:

```powershell
pwsh scripts/deployment/Teardown-All.ps1
```

**What happens:**
- ✅ Deletes all 16 Azure resources
- ✅ Stops all monthly costs ($0/month)
- ✅ Your code, docs, and configs remain on your computer
- ⏱️ Takes 5-15 minutes
- 💾 Terraform state preserved for easy restoration

**What's kept:**
- All scripts and code
- Your documentation files (docs/*.md)
- Terraform configuration
- Terraform state file

### Restore Everything (One Command)

When you want to resume work:

```powershell
pwsh scripts/deployment/Restore-All.ps1
```

**What happens:**
1. ✅ Deploys all Azure infrastructure (3-5 min)
2. ✅ Creates search index with schema
3. ✅ Indexes all documents with embeddings
4. ✅ Validates system is working
5. ⏱️ Total time: 10-15 minutes
6. 💰 Resumes monthly costs (~$25-35)

**Perfect for:**
- Using the POC only when needed
- Demonstrating to stakeholders
- Development/testing cycles
- Keeping costs minimal

### Cost Comparison

| Scenario | Monthly Cost | When to Use |
|----------|--------------|-------------|
| **Always On** | ~$25-35 | Active development |
| **Teardown when idle** | ~$5-10 | Occasional use |
| **Fully destroyed** | $0 | Long breaks |

## Quick Start

### 1. Create the Search Index

```powershell
pwsh scripts/deployment/Create-SearchIndex.ps1
```

This creates the `docs-index` with:
- 13 fields (title, content, document_type, etc.)
- Vector search support (1536 dimensions)
- Hybrid search (vector + keyword)

### 2. Test the System

```powershell
pwsh scripts/deployment/Test-Search.ps1
```

This adds sample documents and validates search is working.

### 3. Search Documents

```powershell
# Keyword search (recommended for free tier)
pwsh scripts/deployment/Search-Documents.ps1 -Query "terraform deploy" -SearchMode keyword

# Show top 10 results
pwsh scripts/deployment/Search-Documents.ps1 -Query "azure infrastructure" -SearchMode keyword -Top 10
```

## Search Modes

### Keyword Search (Recommended)
Fast, no API costs, works well for exact term matching.

```powershell
pwsh scripts/deployment/Search-Documents.ps1 -Query "your query" -SearchMode keyword
```

### Vector Search
Semantic similarity using embeddings. **Currently limited by rate limits.**

```powershell
pwsh scripts/deployment/Search-Documents.ps1 -Query "your query" -SearchMode vector
```

### Hybrid Search (Default)
Combines keyword and vector search for best results. **Currently limited by rate limits.**

```powershell
pwsh scripts/deployment/Search-Documents.ps1 -Query "your query" -SearchMode hybrid
```

## Indexing Documents

### Rate Limit Considerations

The current Azure OpenAI deployment has **very low capacity (1 TPM - Tokens Per Minute)** which causes rate limiting when generating embeddings. This is expected with the free/minimal tier.

#### Options:

**Option A: Use Keyword Search Only**
Skip embeddings entirely and use keyword search, which works well for technical documentation.

**Option B: Index with Long Delays**
The `Index-Documents.ps1` script includes retry logic with 60-second waits:

```powershell
# Index one document at a time
pwsh scripts/deployment/Index-Documents.ps1 -MaxDocuments 1

# Wait a few minutes between runs to avoid rate limits
```

**Option C: Increase OpenAI Capacity**
Edit `terraform/environments/poc/main.tf` and increase capacity:

```terraform
model_deployments = [
  {
    name          = "text-embedding-ada-002"
    model_name    = "text-embedding-ada-002"
    model_version = "2"
    scale_type    = "Standard"
    capacity      = 10  # Increase from 1 to 10 (requires quota request)
  }
]
```

Then run `terraform apply` to update. **Note**: May require Azure quota increase request.

### Full Document Indexing

```powershell
# Index all documents (will hit rate limits with current capacity)
pwsh scripts/deployment/Index-Documents.ps1

# Index limited documents for testing
pwsh scripts/deployment/Index-Documents.ps1 -MaxDocuments 5
```

## Viewing Results

Search results show:
- **Title** - Document title
- **Score** - Relevance score (higher = better match)
- **Type** - Document type (Concept, How-To, Reference, etc.)
- **Level** - Skill level (day1, intermediate, expert)
- **Topics** - Subject areas
- **Tech** - Technologies covered
- **Time** - Estimated reading time
- **Content snippet** - First 200 characters
- **File path** - Source document location

## Testing Queries

Try these example queries:

```powershell
# Find terraform deployment guides
pwsh scripts/deployment/Search-Documents.ps1 -Query "terraform deploy" -SearchMode keyword

# Find infrastructure automation concepts
pwsh scripts/deployment/Search-Documents.ps1 -Query "infrastructure automation" -SearchMode keyword

# Find Azure-specific content
pwsh scripts/deployment/Search-Documents.ps1 -Query "azure" -SearchMode keyword
```

## Uploading Your Own Documents

```powershell
# Upload all markdown files from docs/ folder
pwsh scripts/deployment/Upload-Documents.ps1
```

Documents should have YAML frontmatter:

```yaml
---
document_id: "howto-terraform-deploy"
document_type: "How-To"
skill_level: "day1"
topics: ["Terraform", "Deployment", "Azure"]
technologies: ["Terraform", "Azure CLI"]
search_keywords: ["terraform", "deploy", "infrastructure"]
estimated_time: 15
last_reviewed: "2024-01-15"
---

# Your Document Title

Document content here...
```

## Cost Management

### Current Monthly Costs (~$12)
- Azure AI Search (Free): $0
- Azure OpenAI (S0): ~$0 (pay per use, minimal with low usage)
- Storage Account: ~$1
- Key Vault: ~$1
- Log Analytics: ~$5
- Application Insights: ~$5

### To Reduce Costs
```powershell
# Destroy when not in use
cd terraform/environments/poc
terraform destroy -auto-approve
```

## Troubleshooting

### Rate Limit Errors
If you see "RateLimitReached" errors:
- Use keyword search mode instead of vector/hybrid
- Wait 60+ seconds between embedding requests
- Consider increasing OpenAI deployment capacity

### No Search Results
- Wait 2-3 seconds after indexing before searching
- Check documents were indexed successfully
- Try keyword search mode
- Verify index exists: Azure Portal > Search Service > Indexes

### Connection Errors
- Ensure you're logged into Azure CLI: `az login`
- Verify terraform outputs are accessible
- Check resource group and service names match deployment

## Next Steps

1. **Add More Documents**: Place .md files in `docs/` folder with proper frontmatter
2. **Test Different Search Modes**: Compare keyword vs. vector vs. hybrid results
3. **Monitor Costs**: Check Azure Portal > Cost Management
4. **Scale Up**: When ready, upgrade to Basic tier and increase OpenAI capacity
5. **Build UI**: Create a web interface for search (Function App already deployed)

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     User Query                              │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
         ┌─────────────────────┐
         │ Search-Documents.ps1 │
         └─────────┬───────────┘
                   │
        ┌──────────┴──────────┐
        │                     │
        ▼                     ▼
┌──────────────┐    ┌──────────────────┐
│ Azure OpenAI │    │ Azure AI Search  │
│  (Embeddings)│◄───┤   (Index)        │
└──────────────┘    └────────┬─────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │  Search Results │
                    │  - Title        │
                    │  - Score        │
                    │  - Metadata     │
                    │  - Snippet      │
                    └─────────────────┘
```

## Resources

- **Azure Portal**: https://portal.azure.com
- **Azure AI Search Docs**: https://learn.microsoft.com/azure/search/
- **Azure OpenAI Docs**: https://learn.microsoft.com/azure/ai-services/openai/
- **Terraform Docs**: https://www.terraform.io/docs
- **Project Documentation**: See `docs/` folder

## Support

For issues or questions:
1. Check this usage guide
2. Review `CLAUDE.md` for architecture details
3. Check `README.md` for project overview
4. Review Azure Portal for service health
5. Check deployment scripts for error messages
