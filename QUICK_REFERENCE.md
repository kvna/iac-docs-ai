# Quick Reference Card

## 🚀 Essential Commands

### Ask Questions (Recommended)
```powershell
pwsh scripts/deployment/Ask-Documentation.ps1 -Question "your question here"
```
**ChatGPT-like answers from your docs**

### Search Documents
```powershell
pwsh scripts/deployment/Search-Documents.ps1 -Query "terraform"
```
**Fast document discovery**

---

## 💰 Cost Management

### Stop All Costs
```powershell
pwsh scripts/deployment/Teardown-All.ps1
```
**Deletes everything → $0/month**

### Restore Everything
```powershell
pwsh scripts/deployment/Restore-All.ps1
```
**Recreates all resources in 10-15 min**

---

## 🔧 Manual Operations

### Create Search Index
```powershell
pwsh scripts/deployment/Create-SearchIndex.ps1
```

### Index Documents
```powershell
pwsh scripts/deployment/Index-Documents.ps1
```

### Upload Documents to Storage
```powershell
pwsh scripts/deployment/Upload-Documents.ps1
```

### Quick Validation Test
```powershell
pwsh scripts/deployment/Test-Search.ps1
```

---

## 📖 Example Questions to Ask

```powershell
# Single-source questions
pwsh scripts/deployment/Ask-Documentation.ps1 -Question "What is Infrastructure as Code?"
pwsh scripts/deployment/Ask-Documentation.ps1 -Question "How do I install Terraform?"
pwsh scripts/deployment/Ask-Documentation.ps1 -Question "What naming conventions should I use?"

# Multi-source questions
pwsh scripts/deployment/Ask-Documentation.ps1 -Question "Why is IaC important and how do I get started?"
pwsh scripts/deployment/Ask-Documentation.ps1 -Question "What tools do I need and what naming standards should I follow?"

# Comprehensive onboarding
pwsh scripts/deployment/Ask-Documentation.ps1 -Question "I'm new to IaC - what is it, what do I need, and what standards should I follow?"
```

**See TEST_QUESTIONS.md for 54+ example questions**

---

## 🔍 Search Modes

```powershell
# Keyword search (fastest, no AI cost)
pwsh scripts/deployment/Search-Documents.ps1 -Query "terraform" -SearchMode keyword

# Vector search (semantic understanding)
pwsh scripts/deployment/Search-Documents.ps1 -Query "getting started" -SearchMode vector

# Hybrid search (best results - default)
pwsh scripts/deployment/Search-Documents.ps1 -Query "azure deployment"

# Get more results
pwsh scripts/deployment/Search-Documents.ps1 -Query "terraform" -Top 10
```

---

## 📊 Infrastructure Commands

### Deploy Infrastructure
```bash
cd terraform/environments/poc
terraform apply -auto-approve
```

### Destroy Infrastructure
```bash
cd terraform/environments/poc
terraform destroy -auto-approve
```

### View Deployed Resources
```bash
cd terraform/environments/poc
terraform show
```

### View Terraform Outputs
```bash
cd terraform/environments/poc
terraform output
```

---

## 💡 Tips

**Daily Use:**
- Use `Ask-Documentation.ps1` for Q&A
- Use `Search-Documents.ps1` to browse docs

**Cost Savings:**
- Run `Teardown-All.ps1` when done for the day
- Run `Restore-All.ps1` when you start work

**Adding Documents:**
1. Place .md files in `docs/` folder
2. Run `Index-Documents.ps1`
3. Start asking questions!

**Capacity Issues?**
- Edit `terraform/environments/poc/main.tf`
- Change `capacity = 50` to higher number
- Run `terraform apply`

---

## 📁 Key Files

| File | Purpose |
|------|---------|
| `USAGE_GUIDE.md` | Complete usage documentation |
| `CLAUDE.md` | Architecture & development guide |
| `TEST_QUESTIONS.md` | 54 test questions to try |
| `README.md` | Project overview |
| `terraform/environments/poc/main.tf` | Infrastructure config |
| `docs/*.md` | Your documentation files |

---

## 💰 Costs

| Configuration | Monthly Cost |
|--------------|--------------|
| Always on (current) | ~$25-35 |
| Teardown when idle | ~$5-10 |
| Fully destroyed | $0 |

---

## 🆘 Troubleshooting

**Rate Limit Errors:**
- Wait 60 seconds between requests
- Or increase capacity in main.tf

**No Search Results:**
- Run `Index-Documents.ps1` to reindex
- Wait 2-3 seconds after indexing

**Authentication Errors:**
- Run `az login`
- Verify subscription: `az account show`

**Commands Not Found:**
- Ensure you're in project root: `/home/garyk/code/docai`
- Use full paths: `pwsh scripts/deployment/...`

---

## 🎯 Most Common Workflows

### Daily Use
```powershell
# Ask questions
pwsh scripts/deployment/Ask-Documentation.ps1 -Question "How do I deploy with Terraform?"

# Search docs
pwsh scripts/deployment/Search-Documents.ps1 -Query "azure"
```

### Cost Management (Recommended)
```powershell
# End of day - stop costs
pwsh scripts/deployment/Teardown-All.ps1

# Start of day - restore
pwsh scripts/deployment/Restore-All.ps1
```

### Adding New Documents
```powershell
# 1. Add .md files to docs/ folder
# 2. Index them
pwsh scripts/deployment/Index-Documents.ps1

# 3. Test
pwsh scripts/deployment/Ask-Documentation.ps1 -Question "test question about new content"
```

---

**For detailed information, see USAGE_GUIDE.md**
