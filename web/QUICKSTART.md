# Quick Start Guide - Documentation Search Web Interface

Get the web interface running in 5 minutes!

## Option 1: Local Development (Fastest)

### Step 1: Start the API Backend

```bash
cd web/api

# Copy and configure settings
cp local.settings.json.template local.settings.json

# Edit local.settings.json with your Azure credentials
# Get values from Terraform:
cd ../../terraform/environments/poc
terraform output

# Back to API directory
cd ../../web/api

# Install dependencies
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt

# Start the Function App
func start
```

API will be running at: `http://localhost:7071/api/ask`

### Step 2: Start the Frontend

Open a new terminal:

```bash
cd web/frontend

# Start a simple web server
python -m http.server 8000
# Or use: npx http-server -p 8000
# Or use VS Code Live Server extension
```

Frontend will be at: `http://localhost:8000`

### Step 3: Test It!

1. Open `http://localhost:8000` in your browser
2. Type a question: "How do I install Terraform?"
3. Click Search
4. See the AI-powered answer!

## Option 2: Deploy to Azure

### Prerequisites

- Azure Functions Core Tools: https://aka.ms/azfunc-install
- Azure Static Web Apps CLI: `npm install -g @azure/static-web-apps-cli`
- Terraform already applied (infrastructure exists)

### Deploy Everything

```bash
# Deploy both frontend and backend
pwsh scripts/deployment/Deploy-Web.ps1 -DeployFrontend -DeployBackend

# Or deploy separately:
pwsh scripts/deployment/Deploy-Web.ps1 -DeployBackend    # Just API
pwsh scripts/deployment/Deploy-Web.ps1 -DeployFrontend  # Just UI
```

### Access Your Deployed App

After deployment completes, the script will show your URLs:

```
Frontend UI:
  https://stapp-iac-docs-poc-northeu-xxx.azurestaticapps.net

Backend API:
  https://func-iac-docs-poc-northeu.azurewebsites.net/api/ask
```

## local.settings.json Configuration

Get these values from your Terraform deployment:

```bash
cd terraform/environments/poc

# Get all outputs
terraform output

# Or get specific values
terraform output search_endpoint
terraform output openai_endpoint
```

Then fill in `web/api/local.settings.json`:

```json
{
  "Values": {
    "SEARCH_ENDPOINT": "<from terraform output search_endpoint>",
    "SEARCH_KEY": "<from Azure Portal or terraform>",
    "SEARCH_INDEX": "docs-index",
    "OPENAI_ENDPOINT": "<from terraform output openai_endpoint>",
    "OPENAI_KEY": "<from Azure Portal or terraform>",
    "OPENAI_DEPLOYMENT": "gpt-4",
    "EMBEDDING_DEPLOYMENT": "text-embedding-ada-002"
  }
}
```

### Get API Keys

```bash
# Search service key
az search admin-key show \
  --resource-group rg-iac-docs-poc-northeu \
  --service-name search-iac-docs-poc-northeu \
  --query "primaryKey" -o tsv

# OpenAI key
az cognitiveservices account keys list \
  --resource-group rg-iac-docs-poc-northeu \
  --name openai-iac-docs-poc-northeu \
  --query "key1" -o tsv
```

## Testing the API

### Test locally:

```bash
curl -X POST http://localhost:7071/api/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "How do I install Terraform?"}'
```

### Test deployed:

```bash
curl -X POST https://func-iac-docs-poc-northeu.azurewebsites.net/api/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "How do I install Terraform?"}'
```

Expected response:
```json
{
  "answer": "To install Terraform, follow these steps...",
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

## Troubleshooting

### "Failed to fetch" in browser

**Cause**: Function App not running or CORS issue

**Fix**:
- Local: Ensure `func start` is running
- Deployed: Check Function App is started in Azure Portal
- Check browser console for specific error

### "Server configuration error"

**Cause**: Missing environment variables

**Fix**:
- Local: Verify all values in `local.settings.json`
- Deployed: Check Application Settings in Azure Portal

### Function App starts but times out

**Cause**: OpenAI or Search service not accessible

**Fix**:
- Verify you've indexed documents: `pwsh scripts/deployment/Index-Documents.ps1`
- Check OpenAI deployment exists: `az cognitiveservices account deployment list`
- Verify Search index exists: Check Azure Portal

### Python virtual environment issues

**Windows PowerShell execution policy error**:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Module not found after pip install**:
```bash
deactivate
rm -rf .venv
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Next Steps

Once running:

1. **Try different questions**:
   - "What are Terraform modules?"
   - "How do I manage state?"
   - "Common Terraform errors?"

2. **Customize the UI**:
   - Edit `web/frontend/styles.css` for colors/fonts
   - Modify `web/frontend/index.html` for layout
   - Update `web/frontend/app.js` for behavior

3. **Monitor usage**:
   - Azure Portal → Function App → Monitoring
   - Application Insights for detailed analytics

4. **Add more documents**:
   - Add `.md` files to `/docs`
   - Run `pwsh scripts/deployment/Index-Documents.ps1`
   - Documents automatically searchable!

## Architecture Overview

```
┌──────────────┐
│   Browser    │
│  (Frontend)  │
└──────┬───────┘
       │ HTTP POST /api/ask
       │ { question: "..." }
       ↓
┌──────────────────────┐
│  Azure Function App  │
│   (Python Backend)   │
└──────┬───────────────┘
       │
       ├─→ Azure OpenAI (Generate embedding)
       │
       ├─→ Azure AI Search (Vector search)
       │
       └─→ Azure OpenAI (Generate answer with GPT-4)
```

## Cost Estimate (Local Development)

**$0** - All resources run locally using existing Azure services

## Cost Estimate (Azure Deployment)

- **Static Web App**: $0 (Free tier)
- **Function App**: ~$0.20/month (Consumption plan)
- **Existing services**: Already deployed
- **Total new cost**: ~$0.20/month

Perfect for POC and production use!

---

**Need help?** See full documentation in `/web/README.md`
