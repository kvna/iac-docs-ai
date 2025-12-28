# Documentation Search Web Interface

A modern web interface for searching Infrastructure as Code documentation using AI-powered semantic search.

## Architecture

- **Frontend**: Static HTML/CSS/JavaScript hosted on Azure Static Web Apps
- **Backend**: Azure Functions (Python) providing the search API
- **Search**: Azure AI Search with vector search and GPT-4 for answers

## Local Development

### Prerequisites

- Node.js 18+ (for local development server)
- Python 3.11+ (for Azure Functions)
- Azure Functions Core Tools v4
- Azure CLI

### Setup

1. **Configure API settings**:
   ```bash
   cd api
   cp local.settings.json.template local.settings.json
   # Edit local.settings.json with your Azure resource values
   ```

2. **Install Python dependencies**:
   ```bash
   cd api
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   pip install -r requirements.txt
   ```

3. **Start the Function App locally**:
   ```bash
   cd api
   func start
   # API will be available at http://localhost:7071/api/ask
   ```

4. **Serve the frontend**:
   ```bash
   cd frontend
   # Using Python's http server
   python -m http.server 8000

   # Or using VS Code Live Server extension
   # Or using Node's http-server: npx http-server -p 8000
   ```

5. **Open browser**:
   ```
   http://localhost:8000
   ```

## Azure Deployment

### Option 1: Using Terraform (Recommended)

The web resources are defined in `/terraform/environments/poc/web.tf`.

1. **Navigate to Terraform directory**:
   ```bash
   cd terraform/environments/poc
   ```

2. **Initialize and apply**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **Get deployment URLs**:
   ```bash
   terraform output static_web_app_url
   terraform output function_app_url
   ```

4. **Deploy Function App code**:
   ```bash
   cd ../../../web/api
   func azure functionapp publish $(terraform -chdir=../../terraform/environments/poc output -raw function_app_name)
   ```

5. **Deploy Static Web App**:
   ```bash
   # Get the API key
   SWA_TOKEN=$(terraform -chdir=../../terraform/environments/poc output -raw static_web_app_api_key)

   # Install Azure Static Web Apps CLI
   npm install -g @azure/static-web-apps-cli

   # Deploy
   cd ../frontend
   swa deploy --app-location . --deployment-token $SWA_TOKEN
   ```

### Option 2: Using Azure CLI

1. **Deploy Function App**:
   ```bash
   cd api

   # Package the function
   zip -r function-app.zip . -x "*.pyc" "__pycache__/*" ".venv/*"

   # Deploy
   az functionapp deployment source config-zip \
     --resource-group rg-iac-docs-poc-northeu \
     --name func-iac-docs-poc-northeu \
     --src function-app.zip
   ```

2. **Deploy Static Web App**:
   ```bash
   cd frontend

   # Get the deployment token
   SWA_TOKEN=$(az staticwebapp secrets list \
     --name stapp-iac-docs-poc-northeu \
     --resource-group rg-iac-docs-poc-northeu \
     --query "properties.apiKey" -o tsv)

   # Deploy using SWA CLI
   npx @azure/static-web-apps-cli deploy \
     --app-location . \
     --deployment-token $SWA_TOKEN
   ```

## Configuration

### Frontend Configuration

The frontend automatically detects the environment:
- **Local development**: Calls `http://localhost:7071/api/ask`
- **Production**: Calls `/api/ask` (proxied through Static Web App)

No configuration changes needed!

### Backend Configuration

Function App environment variables (set via Terraform or Azure Portal):

| Variable | Description | Example |
|----------|-------------|---------|
| `SEARCH_ENDPOINT` | Azure AI Search endpoint | `https://search-xxx.search.windows.net` |
| `SEARCH_KEY` | Search service admin key | Auto-configured by Terraform |
| `SEARCH_INDEX` | Search index name | `docs-index` |
| `OPENAI_ENDPOINT` | Azure OpenAI endpoint | `https://openai-xxx.openai.azure.com` |
| `OPENAI_KEY` | OpenAI API key | Auto-configured by Terraform |
| `OPENAI_DEPLOYMENT` | GPT deployment name | `gpt-4` |
| `EMBEDDING_DEPLOYMENT` | Embedding deployment name | `text-embedding-ada-002` |

## Testing

### Test the Function App locally

```bash
curl -X POST http://localhost:7071/api/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "How do I install Terraform?"}'
```

Expected response:
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

### Test the deployed Function App

```bash
FUNCTION_URL=$(terraform -chdir=terraform/environments/poc output -raw function_app_url)

curl -X POST https://$FUNCTION_URL/api/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "How do I install Terraform?"}'
```

## Project Structure

```
web/
├── frontend/                     # Static web frontend
│   ├── index.html               # Main HTML page
│   ├── styles.css               # Styles
│   ├── app.js                   # Frontend logic
│   └── staticwebapp.config.json # Azure Static Web App config
├── api/                         # Azure Functions backend
│   ├── ask/                     # HTTP trigger function
│   │   ├── __init__.py         # Main function code
│   │   └── function.json       # Function configuration
│   ├── host.json               # Function app settings
│   ├── requirements.txt        # Python dependencies
│   └── local.settings.json.template  # Local settings template
└── README.md                    # This file
```

## Features

### Frontend
- Clean, modern UI with responsive design
- Real-time search as you type
- Markdown rendering for answers
- Source attribution with document metadata
- Quick question suggestions
- Example questions by category
- Loading states and error handling

### Backend API
- POST `/api/ask` - Answer documentation questions
  - Request: `{ "question": "your question here" }`
  - Response: `{ "answer": "...", "sources": [...], "question": "..." }`
- CORS enabled for local development and production
- Vector search using Azure AI Search
- GPT-4 for answer generation
- Application Insights integration

## Monitoring

View logs in Azure Portal:
- **Function App**: Monitor > Logs
- **Static Web App**: Monitoring > Application Insights
- **Application Insights**: Search, failures, performance metrics

Or use Azure CLI:
```bash
# Function App logs
az webapp log tail \
  --name func-iac-docs-poc-northeu \
  --resource-group rg-iac-docs-poc-northeu

# Application Insights queries
az monitor app-insights query \
  --app $(terraform -chdir=terraform/environments/poc output -raw application_insights_name) \
  --analytics-query "requests | where timestamp > ago(1h) | project timestamp, name, url, success, resultCode"
```

## Cost Optimization

### Pricing Tiers (POC Configuration)
- **Static Web App**: Free tier (100 GB bandwidth/month, custom domains)
- **Function App**: Consumption plan (Y1) - pay per execution
- **Azure AI Search**: Basic tier ($75/month)
- **Azure OpenAI**: Pay per token

### Estimated Monthly Cost
- Static Web App: **$0**
- Function App: **~$0.20** (1M executions)
- Azure AI Search: **$75**
- Azure OpenAI: **~$10-50** (depends on usage)

**Total: ~$85-125/month**

### Cost Reduction Tips
1. Use Azure AI Search Free tier if sufficient (15 MB storage limit)
2. Set up auto-shutdown for non-production hours
3. Monitor token usage in OpenAI
4. Cache common queries (future enhancement)

## Troubleshooting

### "Failed to fetch" error in browser
- Check Function App is running: `func start` for local, or check Azure Portal for deployed
- Verify CORS settings in Function App
- Check browser console for specific error

### "Server configuration error" response
- Verify all environment variables are set in `local.settings.json` or Azure Portal
- Check Function App logs for specific missing variable

### Function App deployment fails
- Ensure Python 3.11 is installed
- Check all dependencies in `requirements.txt` are compatible
- Verify Function App SKU supports Linux (Y1, B1, S1)

### Static Web App deployment fails
- Verify deployment token is correct
- Check Azure Static Web Apps CLI is installed: `npm install -g @azure/static-web-apps-cli`
- Ensure you're in the `frontend` directory when deploying

## Next Steps

1. **Add authentication**: Integrate Azure AD for user authentication
2. **Implement caching**: Redis Cache for frequently asked questions
3. **Add analytics**: Track popular questions and user engagement
4. **Enhance UI**: Add filters, sorting, document preview
5. **CI/CD**: GitHub Actions or Azure DevOps pipeline for automated deployment
6. **Multi-language**: Support multiple languages for questions and answers

## Support

- **Documentation**: See `/docs` for detailed documentation
- **Issues**: Report gaps using `pwsh scripts/quality/Report-Documentation-Gap.ps1`
- **Team**: Contact iac-team@company.com
