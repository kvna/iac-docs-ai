# Frontend Deployment Instructions

Your frontend is configured and ready to use! The API backend is already deployed and working.

## ✅ Quick Test (Works Right Now!)

The frontend is configured to use your deployed API. You can test it locally:

```bash
cd /home/garyk/code/docai/web/frontend

# Start a local web server
python3 -m http.server 8000

# Open in browser: http://localhost:8000
```

**The frontend will work perfectly locally and call your deployed Azure API!** ✨

---

## 🚀 Deploy to Azure Static Web Apps (Recommended: GitHub Actions)

The best way to deploy to Azure Static Web Apps is using GitHub Actions:

### Step 1: Create GitHub Repository

```bash
cd /home/garyk/code/docai
git init
git add .
git commit -m "Initial commit - Documentation search system"

# Create a repository on GitHub, then:
git remote add origin https://github.com/YOUR-USERNAME/YOUR-REPO.git
git push -u origin main
```

### Step 2: Connect to Static Web App

1. Go to Azure Portal: https://portal.azure.com
2. Navigate to your Static Web App: **stapp-iac-docs-poc-northeu**
3. Click **"Manage deployment token"** and copy the token
4. In your GitHub repo, go to **Settings → Secrets and variables → Actions**
5. Add a new secret named `AZURE_STATIC_WEB_APPS_API_TOKEN` with the token value

### Step 3: Add GitHub Actions Workflow

Create `.github/workflows/azure-static-web-apps.yml`:

```yaml
name: Deploy to Azure Static Web Apps

on:
  push:
    branches:
      - main
  pull_request:
    types: [opened, synchronize, reopened, closed]
    branches:
      - main

jobs:
  build_and_deploy:
    if: github.event_name == 'push' || (github.event_name == 'pull_request' && github.event.action != 'closed')
    runs-on: ubuntu-latest
    name: Build and Deploy
    steps:
      - uses: actions/checkout@v3
        with:
          submodules: true

      - name: Build And Deploy
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
          repo_token: ${{ secrets.GITHUB_TOKEN }}
          action: "upload"
          app_location: "/web/frontend"
          api_location: ""
          output_location: ""

  close_pull_request:
    if: github.event_name == 'pull_request' && github.event.action == 'closed'
    runs-on: ubuntu-latest
    name: Close Pull Request
    steps:
      - name: Close Pull Request
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
          action: "close"
```

### Step 4: Push and Auto-Deploy

```bash
git add .github/workflows/azure-static-web-apps.yml
git commit -m "Add GitHub Actions deployment workflow"
git push
```

GitHub Actions will automatically deploy your frontend! Check the **Actions** tab to see progress.

---

## 🎯 Your URLs After Deployment

- **Frontend:** https://witty-flower-02f921703.4.azurestaticapps.net
- **API:** https://func-iac-docs-poc-northeu.azurewebsites.net/api/ask

---

## 🔧 Alternative: Manual Deployment (Advanced)

If you don't want to use GitHub, you can deploy using Azure CLI:

```bash
# Get deployment token
TOKEN=$(az staticwebapp secrets list \
  --name stapp-iac-docs-poc-northeu \
  --resource-group rg-iac-docs-poc-northeu \
  --query "properties.apiKey" -o tsv)

# Install SWA CLI globally (with sudo if needed)
sudo npm install -g @azure/static-web-apps-cli

# Deploy
cd /home/garyk/code/docai/web/frontend
swa deploy --app-location . --deployment-token $TOKEN --no-use-keychain
```

---

## 📝 Current Status

✅ **Backend API:** Deployed and working
✅ **Frontend Code:** Ready and configured
✅ **Local Testing:** Works right now!
⏳ **Azure Static Web App:** Awaiting frontend files (use GitHub Actions above)

---

## 🧪 Test Locally Right Now

```bash
# 1. Start server
cd /home/garyk/code/docai/web/frontend
python3 -m http.server 8000

# 2. Open browser
# http://localhost:8000

# 3. Try these questions:
#    - How do I install Terraform?
#    - What are Terraform modules?
#    - How do I manage state?
```

**Your frontend works perfectly locally and calls the deployed Azure API!** 🎉
