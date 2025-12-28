<#
.SYNOPSIS
    Deploy the documentation search web interface to Azure

.DESCRIPTION
    Deploys both the Static Web App frontend and the Azure Functions backend.
    Infrastructure must already be deployed via Terraform.

.PARAMETER DeployFrontend
    Deploy the Static Web App frontend

.PARAMETER DeployBackend
    Deploy the Azure Functions backend

.PARAMETER ResourceGroupName
    Resource group name (optional, will use Terraform output if not provided)

.EXAMPLE
    .\Deploy-Web.ps1 -DeployFrontend -DeployBackend

.EXAMPLE
    .\Deploy-Web.ps1 -DeployBackend

.NOTES
    Requires: Azure Functions Core Tools, Azure Static Web Apps CLI (optional)
#>

[CmdletBinding()]
param (
    [Parameter()]
    [switch]$DeployFrontend,

    [Parameter()]
    [switch]$DeployBackend,

    [Parameter()]
    [string]$ResourceGroupName,

    [Parameter()]
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "🚀 Web Interface Deployment" -ForegroundColor Cyan
Write-Host "=" * 60

# Check if at least one deployment option is selected
if (-not $DeployFrontend -and -not $DeployBackend) {
    Write-Host "❌ Please specify at least one deployment option:" -ForegroundColor Red
    Write-Host "   -DeployFrontend   Deploy Static Web App" -ForegroundColor Yellow
    Write-Host "   -DeployBackend    Deploy Function App" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Get Terraform outputs
Write-Host ""
Write-Host "📋 Getting deployment information from Terraform..." -ForegroundColor Yellow

$terraformPath = Join-Path $PSScriptRoot "..\..\terraform\environments\poc"
Push-Location $terraformPath

try {
    $outputs = terraform output -json | ConvertFrom-Json

    if (-not $ResourceGroupName) {
        $ResourceGroupName = $outputs.resource_group_name.value
    }

    $functionAppName = $outputs.function_app_name.value
    $staticWebAppName = "stapp-iac-docs-poc-northeu"  # From Terraform naming

    Write-Host "  ✓ Resource Group: $ResourceGroupName" -ForegroundColor Green
    Write-Host "  ✓ Function App: $functionAppName" -ForegroundColor Green
    Write-Host "  ✓ Static Web App: $staticWebAppName" -ForegroundColor Green
}
finally {
    Pop-Location
}

##############################################################################
# Deploy Function App Backend
##############################################################################

if ($DeployBackend) {
    Write-Host ""
    Write-Host "📦 Deploying Azure Functions Backend..." -ForegroundColor Cyan
    Write-Host "=" * 60

    $apiPath = Join-Path $PSScriptRoot "..\..\web\api"
    Push-Location $apiPath

    try {
        # Check if func is installed
        $funcVersion = func --version 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Azure Functions Core Tools not found!" -ForegroundColor Red
            Write-Host "   Install from: https://docs.microsoft.com/azure/azure-functions/functions-run-local" -ForegroundColor Yellow
            exit 1
        }

        Write-Host "  Using Azure Functions Core Tools: $funcVersion" -ForegroundColor Gray

        # Create Python virtual environment if it doesn't exist
        if (-not (Test-Path ".venv")) {
            Write-Host ""
            Write-Host "📦 Creating Python virtual environment..." -ForegroundColor Yellow
            python -m venv .venv
        }

        # Activate venv and install dependencies
        Write-Host ""
        Write-Host "📦 Installing Python dependencies..." -ForegroundColor Yellow

        if ($IsWindows) {
            & .\.venv\Scripts\Activate.ps1
        } else {
            # For Linux/Mac, we'll use pip directly
            & ./.venv/bin/pip install -r requirements.txt --quiet
        }

        # Deploy to Azure
        Write-Host ""
        Write-Host "🚀 Publishing to Azure Function App..." -ForegroundColor Yellow
        Write-Host "   This may take a few minutes..." -ForegroundColor Gray

        func azure functionapp publish $functionAppName --python

        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✅ Function App deployed successfully!" -ForegroundColor Green

            $functionUrl = "https://$functionAppName.azurewebsites.net/api/ask"
            Write-Host ""
            Write-Host "🌐 Function App URL:" -ForegroundColor Cyan
            Write-Host "   $functionUrl" -ForegroundColor White

            # Test the endpoint
            Write-Host ""
            Write-Host "🧪 Testing endpoint..." -ForegroundColor Yellow
            try {
                $testResponse = Invoke-RestMethod `
                    -Method Post `
                    -Uri $functionUrl `
                    -ContentType "application/json" `
                    -Body '{"question":"What is Infrastructure as Code?"}' `
                    -TimeoutSec 30

                Write-Host "   ✓ Endpoint is responding!" -ForegroundColor Green
            }
            catch {
                Write-Host "   ⚠️  Endpoint test failed (this is normal right after deployment)" -ForegroundColor Yellow
                Write-Host "      The function may need a few minutes to start. Try again later." -ForegroundColor Gray
            }
        }
        else {
            Write-Host ""
            Write-Host "❌ Function App deployment failed!" -ForegroundColor Red
            exit 1
        }
    }
    finally {
        Pop-Location
    }
}

##############################################################################
# Deploy Static Web App Frontend
##############################################################################

if ($DeployFrontend) {
    Write-Host ""
    Write-Host "🎨 Deploying Static Web App Frontend..." -ForegroundColor Cyan
    Write-Host "=" * 60

    # Get deployment token
    Write-Host "  Getting deployment token..." -ForegroundColor Yellow

    $deployToken = az staticwebapp secrets list `
        --name $staticWebAppName `
        --resource-group $ResourceGroupName `
        --query "properties.apiKey" `
        --output tsv

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($deployToken)) {
        Write-Host "❌ Failed to get Static Web App deployment token!" -ForegroundColor Red
        exit 1
    }

    Write-Host "  ✓ Deployment token retrieved" -ForegroundColor Green

    # Check if SWA CLI is installed
    $swaInstalled = $false
    try {
        swa --version 2>$null | Out-Null
        $swaInstalled = $true
    }
    catch {
        $swaInstalled = $false
    }

    if (-not $swaInstalled) {
        Write-Host ""
        Write-Host "📦 Azure Static Web Apps CLI not found. Installing..." -ForegroundColor Yellow
        npm install -g @azure/static-web-apps-cli

        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Failed to install SWA CLI!" -ForegroundColor Red
            Write-Host "   Install manually: npm install -g @azure/static-web-apps-cli" -ForegroundColor Yellow
            exit 1
        }
    }

    # Deploy frontend
    $frontendPath = Join-Path $PSScriptRoot "..\..\web\frontend"
    Push-Location $frontendPath

    try {
        Write-Host ""
        Write-Host "🚀 Deploying to Azure Static Web Apps..." -ForegroundColor Yellow
        Write-Host "   This may take a few minutes..." -ForegroundColor Gray

        swa deploy --app-location . --deployment-token $deployToken --no-use-keychain

        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✅ Static Web App deployed successfully!" -ForegroundColor Green

            # Get the URL
            $webAppUrl = az staticwebapp show `
                --name $staticWebAppName `
                --resource-group $ResourceGroupName `
                --query "defaultHostname" `
                --output tsv

            Write-Host ""
            Write-Host "🌐 Web App URL:" -ForegroundColor Cyan
            Write-Host "   https://$webAppUrl" -ForegroundColor White
        }
        else {
            Write-Host ""
            Write-Host "❌ Static Web App deployment failed!" -ForegroundColor Red
            exit 1
        }
    }
    finally {
        Pop-Location
    }
}

##############################################################################
# Summary
##############################################################################

Write-Host ""
Write-Host "=" * 60
Write-Host "✅ Deployment Complete!" -ForegroundColor Green
Write-Host ""

if ($DeployBackend) {
    Write-Host "Backend API:" -ForegroundColor Cyan
    Write-Host "  https://$functionAppName.azurewebsites.net/api/ask" -ForegroundColor White
}

if ($DeployFrontend) {
    Write-Host "Frontend UI:" -ForegroundColor Cyan
    Write-Host "  https://$webAppUrl" -ForegroundColor White
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Open the web app in your browser" -ForegroundColor Gray
Write-Host "  2. Try searching: 'How do I install Terraform?'" -ForegroundColor Gray
Write-Host "  3. Monitor logs in Azure Portal or Application Insights" -ForegroundColor Gray
Write-Host ""
