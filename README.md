# IaC Documentation Modernization & AI Search POC

**A comprehensive solution for IaC team documentation with AI-powered natural language search**

[![Documentation System](https://img.shields.io/badge/Docs-System%20Guide-blue)](DOCUMENTATION_SYSTEM_GUIDE.md)
[![Terraform](https://img.shields.io/badge/Terraform-1.5+-purple)](https://www.terraform.io/)
[![Azure](https://img.shields.io/badge/Azure-AI%20Search-0078D4)](https://azure.microsoft.com/en-us/services/search/)
[![PowerShell](https://img.shields.io/badge/PowerShell-7.4+-blue)](https://github.com/PowerShell/PowerShell)

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Cost Estimates](#cost-estimates)
- [Documentation](#documentation)
- [Contributing](#contributing)

---

## 🎯 Overview

This project modernizes IaC team documentation with:

1. **Structured Documentation System**: Progressive learning framework (Day 1 → 12 months)
2. **AI-Powered Search**: Natural language search using Azure AI Search + OpenAI
3. **Quality Automation**: Automated validation of documentation standards
4. **Complete IaC**: Full Terraform infrastructure for POC deployment

### Problem Solved

**Before**: Tribal knowledge, inconsistent onboarding, difficult information discovery, stale documentation

**After**: Self-service documentation, 40-60% faster onboarding, AI-powered search, automated quality standards

---

## ✨ Features

### Documentation System

- ✅ **5 Document Types**: Concept, How-To, Reference, Troubleshooting, Learning Paths
- ✅ **Progressive Learning**: Clear skill progression from Day 1 through 12 months
- ✅ **Glossary System**: Single source of truth for all terminology
- ✅ **Rich Metadata**: AI-optimized metadata for search and discovery
- ✅ **Quality Templates**: Consistent structure across all documentation

### AI Search POC

- ✅ **Azure AI Search**: Semantic ranking and hybrid search
- ✅ **Azure OpenAI**: Embeddings (ada-002) and query enhancement (gpt-4o-mini)
- ✅ **Function App API**: RESTful search endpoints
- ✅ **Cost-Optimized**: Free tier option, easy deploy/destroy

### Automation

- ✅ **Quality Validation**: Automated document quality scoring
- ✅ **IaC Deployment**: One-command infrastructure deployment
- ✅ **Easy Cleanup**: Complete destroy capability to stop costs

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     User Interface Layer                     │
│  ┌────────────────┐  ┌──────────────────┐  ┌─────────────┐ │
│  │ Web Interface  │  │ API Endpoint     │  │ Test Harness│ │
│  │ (Static HTML)  │  │ (Function App)   │  │ (PowerShell)│ │
│  └────────┬───────┘  └────────┬─────────┘  └──────┬──────┘ │
└───────────┼──────────────────┼────────────────────┼────────┘
            │                  │                    │
            └──────────────────┼────────────────────┘
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                   Azure AI Search Service                    │
│  - Semantic Ranking                                          │
│  - Vector Search (embeddings)                                │
│  - Custom Analyzers                                          │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   Azure OpenAI Service                       │
│  - text-embedding-ada-002 (embeddings)                       │
│  - gpt-4o-mini (query enhancement)                           │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   Azure Blob Storage                         │
│  - Markdown documents                                        │
│  - Metadata files                                            │
└─────────────────────────────────────────────────────────────┘
```

### Azure Resources

| Resource | Purpose | SKU Options |
|----------|---------|-------------|
| **AI Search** | Document indexing & search | Free / Basic / Standard |
| **Azure OpenAI** | Embeddings & query processing | S0 (standard) |
| **Storage Account** | Document storage | Standard LRS |
| **Function App** | API endpoints | Consumption / Basic |
| **Key Vault** | Secret management | Standard |
| **App Insights** | Monitoring | Pay-as-you-go |

---

## 🚀 Quick Start

### **Option 1: Fully Automated (Recommended)** ⚡

**Just run one command and answer prompts:**

```powershell
pwsh ./Quick-Start.ps1
```

This automatically:
- ✅ Checks all prerequisites (Terraform, Azure CLI, PowerShell)
- ✅ Verifies Azure authentication and permissions
- ✅ Validates Azure OpenAI access
- ✅ Deploys infrastructure to Azure
- ✅ Shows you what was created and next steps

**Total time: ~15 minutes** | **Cost: ~$12/month**

---

### **Option 2: Check Prerequisites First** 🔍

**Want to verify everything before deploying?**

```powershell
# Check all prerequisites
pwsh ./scripts/deployment/Test-Prerequisites.ps1
```

This validates:
- PowerShell 7.4+
- Terraform 1.5+
- Azure CLI 2.50+
- Azure authentication
- Subscription permissions
- Azure OpenAI availability
- Region availability

**Then deploy when ready:**

```powershell
# Auto-deploy if checks pass
pwsh ./scripts/deployment/Test-Prerequisites.ps1 -Deploy
```

---

### **Option 3: Manual Step-by-Step** 📝

**Prefer full control over each step?**

**1. Authenticate to Azure**
```bash
az login
az account set --subscription "Your-Subscription-Name"
```

**2. Review Proposal** (optional but recommended)
```bash
cat IaC_Documentation_Modernization_Proposal.md
```

**3. Deploy Infrastructure**
```powershell
# Deploy with free tier (recommended for initial testing)
pwsh ./scripts/deployment/Deploy-IaCDocsPOC.ps1

# Or deploy with basic tier for production-like testing
pwsh ./scripts/deployment/Deploy-IaCDocsPOC.ps1 -SearchSku basic
```

**Deployment takes ~5-10 minutes**

**4. Validate Documentation**
```powershell
# Test a single document
pwsh ./scripts/validation/Test-DocumentQuality.ps1 -Path "./docs/day1/concept-iac-overview.md"

# Test all documentation
pwsh ./scripts/validation/Test-DocumentQuality.ps1 -Path "./docs"
```

**5. Destroy When Done**
```powershell
# Remove all Azure resources to stop costs
pwsh ./scripts/deployment/Destroy-IaCDocsPOC.ps1
```

---

### ⚠️ Important: Prerequisites

All options require:
- **PowerShell 7.4+**
- **Azure CLI 2.50+**
- **Terraform 1.5+**
- **Azure Subscription** with Owner or Contributor access
- **Azure OpenAI** access (may require申请 at https://aka.ms/oai/access)

**The automated scripts will check these for you!**

---

## 📁 Project Structure

```
iac-documentation/
├── IaC_Documentation_Modernization_Proposal.md   # Comprehensive proposal
├── DOCUMENTATION_SYSTEM_GUIDE.md                  # System documentation
├── README.md                                      # This file
│
├── config/
│   └── glossary.yaml                              # Canonical term definitions
│
├── templates/                                     # Document templates
│   ├── concept-template.md
│   ├── howto-template.md
│   ├── reference-template.md
│   ├── troubleshooting-template.md
│   └── learning-path-template.md
│
├── docs/                                          # Sample documentation
│   ├── day1/                                      # Day 1 documents
│   ├── week1-4/                                   # Week 1-4 documents
│   ├── month1-2/                                  # Month 1-2 documents
│   ├── month3-6/                                  # Month 3-6 documents
│   ├── month6-12/                                 # Month 6-12 documents
│   ├── reference/                                 # Reference documents
│   ├── troubleshooting/                           # Troubleshooting guides
│   ├── learning-paths/                            # Learning paths
│   └── DOCUMENT_MANIFEST.md                       # Complete doc list
│
├── terraform/                                     # Infrastructure as Code
│   ├── environments/
│   │   └── poc/
│   │       ├── main.tf                            # Main configuration
│   │       ├── variables.tf                       # Variable definitions
│   │       ├── terraform.tfvars.example           # Example values
│   │       └── README.md                          # Deployment guide
│   └── modules/
│       ├── storage/                               # Storage account module
│       ├── search/                                # AI Search module
│       ├── openai/                                # OpenAI module
│       └── function-app/                          # Function App module
│
├── scripts/
│   ├── deployment/
│   │   ├── Deploy-IaCDocsPOC.ps1                  # Deploy infrastructure
│   │   └── Destroy-IaCDocsPOC.ps1                 # Destroy infrastructure
│   ├── validation/
│   │   └── Test-DocumentQuality.ps1               # Quality validation
│   └── testing/
│       └── Test-SearchQuality.ps1                 # Search relevance tests
│
└── web/                                           # Web interface
    ├── api/                                       # Function App code
    └── ui/                                        # Static web UI
```

---

## 💰 Cost Estimates

### Free Tier POC (Recommended for Testing)

| Resource | SKU | Monthly Cost |
|----------|-----|--------------|
| AI Search | Free | **$0** |
| Azure OpenAI | S0 (pay-per-use) | ~$10 |
| Storage | Standard LRS | ~$1 |
| Function App | Consumption | **$0** (free tier) |
| App Insights | Pay-as-you-go | ~$1 |
| **Total** | | **~$12/month** |

### Basic Tier (Production-Like)

| Resource | SKU | Monthly Cost |
|----------|-----|--------------|
| AI Search | Basic | **$75** |
| Azure OpenAI | S0 | ~$15 |
| Storage | Standard LRS | ~$1 |
| Function App | Consumption | **$0** |
| App Insights | Pay-as-you-go | ~$2 |
| **Total** | | **~$93/month** |

### Cost Management

- ✅ **Deploy/Destroy Scripts**: Zero cost when not running
- ✅ **Free Tier Available**: $0 infrastructure cost for testing
- ✅ **Cost Alerts**: Configure in Azure Portal
- ✅ **Resource Tags**: `AutoShutdown = true` for automation

**To stop all costs**: Run `.\scripts\deployment\Destroy-IaCDocsPOC.ps1`

---

## 📚 Documentation

### For Learners

1. **Start Here**: [Day 1 Learning Path](docs/learning-paths/learning-path-day1.md)
2. **Understand System**: [Documentation System Guide](DOCUMENTATION_SYSTEM_GUIDE.md)
3. **Glossary**: [Complete Glossary](config/glossary.yaml)

### For Authors

1. **System Guide**: [Documentation System Guide](DOCUMENTATION_SYSTEM_GUIDE.md)
2. **Templates**: [templates/](templates/)
3. **Quality Standards**: Run validation script before submitting

### For DevOps/Infrastructure

1. **Deployment**: [Terraform README](terraform/environments/poc/README.md)
2. **PowerShell Scripts**: [scripts/deployment/](scripts/deployment/)
3. **Architecture**: See [Architecture](#architecture) section above

---

## 🧪 Testing

### Document Quality Validation

```powershell
# Validate a single document
.\scripts\validation\Test-DocumentQuality.ps1 `
    -Path ".\docs\day1\concept-iac-overview.md"

# Validate all documents
.\scripts\validation\Test-DocumentQuality.ps1 `
    -Path ".\docs" `
    -Verbose

# Set minimum passing score
.\scripts\validation\Test-DocumentQuality.ps1 `
    -Path ".\docs" `
    -MinScore 85
```

### Search Quality Testing

```powershell
# Test search relevance (requires deployed infrastructure)
.\scripts\testing\Test-SearchQuality.ps1 `
    -TestQueries @(
        "how to deploy terraform",
        "what is infrastructure as code",
        "troubleshoot authentication error"
    )
```

---

## 🛠️ Development

### Adding New Documentation

1. Choose appropriate template from `templates/`
2. Copy to correct `docs/` subdirectory based on skill level
3. Fill in all metadata fields
4. Write content following template structure
5. Validate quality: `.\scripts\validation\Test-DocumentQuality.ps1 -Path your-doc.md`
6. Submit PR

### Modifying Infrastructure

1. Edit Terraform files in `terraform/`
2. Test with `terraform plan`
3. Update documentation
4. Submit PR

### CI/CD Integration

The validation script can be integrated into Azure DevOps pipelines:

```yaml
- task: PowerShell@2
  displayName: 'Validate Documentation Quality'
  inputs:
    targetType: 'filePath'
    filePath: '$(Build.SourcesDirectory)/scripts/validation/Test-DocumentQuality.ps1'
    arguments: '-Path "$(Build.SourcesDirectory)/docs" -MinScore 80'
    pwsh: true
```

---

## 📊 Success Metrics

### Documentation Quality

- **Metadata Completeness**: 100% (enforced by validation)
- **Readability Score**: 80+ average
- **Searchability Score**: 80+ average
- **Link Integrity**: 98%+ working links

### User Outcomes

- **Onboarding Time**: 40-60% reduction (target)
- **Self-Service Resolution**: 80%+ of questions answerable via search
- **Documentation Satisfaction**: NPS > 50 (target)

### Infrastructure

- **Deployment Time**: < 10 minutes
- **Search Query Time**: < 3 seconds average
- **Search Relevance**: Top result relevant 90%+ of time

---

## 🤝 Contributing

### For Documentation

1. Fork the repository
2. Create documentation from templates
3. Run quality validation
4. Submit pull request
5. Address review feedback

### For Infrastructure

1. Fork the repository
2. Make changes to Terraform modules
3. Test with `terraform plan`
4. Update documentation
5. Submit pull request

### For Scripts

1. Follow PowerShell best practices
2. Include comment-based help
3. Test on Windows and Linux (PowerShell Core)
4. Submit pull request

---

## 📝 Sample Documents Included

The repository includes complete sample documents demonstrating all document types:

- ✅ **concept-iac-overview.md**: Introduction to Infrastructure as Code
- ✅ **howto-environment-setup.md**: Development environment setup
- ✅ **reference-naming-conventions.md**: Azure resource naming standards
- ✅ **troubleshooting-authentication-issues.md**: Authentication troubleshooting
- ✅ **learning-path-day1.md**: Day 1 complete learning path

Plus a manifest of 50+ planned documents showing the complete documentation vision.

---

## 🔗 Related Resources

### Microsoft Documentation

- [Azure AI Search](https://learn.microsoft.com/azure/search/)
- [Azure OpenAI Service](https://learn.microsoft.com/azure/ai-services/openai/)
- [Terraform on Azure](https://learn.microsoft.com/azure/developer/terraform/)

### HashiCorp Documentation

- [Terraform Documentation](https://www.terraform.io/docs)
- [Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

### PowerShell

- [PowerShell 7 Documentation](https://learn.microsoft.com/powershell/)
- [Azure PowerShell](https://learn.microsoft.com/powershell/azure/)

---

## 📄 License

This project is licensed under the MIT License - see LICENSE file for details.

---

## 🙋 Support

### Questions or Issues?

1. Check [Documentation System Guide](DOCUMENTATION_SYSTEM_GUIDE.md)
2. Review [Proposal Document](IaC_Documentation_Modernization_Proposal.md)
3. Open an issue on GitHub

### Feedback

We welcome feedback on:
- Documentation clarity and usefulness
- Infrastructure deployment experience
- Search quality and relevance
- Cost optimization suggestions

---

**Built with ❤️ for better IaC documentation and faster team onboarding**

---

## 🗺️ Next Steps

After reviewing this POC:

1. ✅ **Review Proposal**: Read `IaC_Documentation_Modernization_Proposal.md`
2. ✅ **Understand System**: Read `DOCUMENTATION_SYSTEM_GUIDE.md`
3. ✅ **Deploy POC**: Run deployment script to see it in action
4. ✅ **Test Search**: Upload docs and test AI search
5. ✅ **Provide Feedback**: Share your thoughts
6. ✅ **Plan Rollout**: Decide on production deployment timeline

**Ready to revolutionize your IaC documentation!** 🚀
