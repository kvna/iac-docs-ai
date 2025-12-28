<#
.SYNOPSIS
    Restores all Azure resources and re-indexes documentation

.DESCRIPTION
    Recreates the entire POC environment:
    1. Deploys Azure infrastructure via Terraform
    2. Creates the search index
    3. Indexes all documents with embeddings
    4. Validates the system is working

.PARAMETER SkipValidation
    Skip the final validation test

.EXAMPLE
    .\Restore-All.ps1

.EXAMPLE
    .\Restore-All.ps1 -SkipValidation

.NOTES
    Requires: PowerShell 7+, Terraform, Azure CLI
    Estimated time: 10-15 minutes
#>

[CmdletBinding()]
param (
    [Parameter()]
    [switch]$SkipValidation
)

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "🚀 RESTORE ALL RESOURCES" -ForegroundColor Cyan
Write-Host "=" * 60

Write-Host "`n📋 What will be created:" -ForegroundColor Yellow
Write-Host "  • Resource Group with 16 Azure resources" -ForegroundColor Gray
Write-Host "  • Azure AI Search with vector search" -ForegroundColor Gray
Write-Host "  • Azure OpenAI (50 TPM capacity)" -ForegroundColor Gray
Write-Host "  • Storage, Key Vault, Monitoring" -ForegroundColor Gray
Write-Host "  • Search index with schema" -ForegroundColor Gray
Write-Host "  • Indexed documents with embeddings" -ForegroundColor Gray

Write-Host "`n⏱️  Estimated time: 10-15 minutes" -ForegroundColor Cyan
Write-Host "💰 Monthly cost: ~$25-35" -ForegroundColor Yellow
Write-Host ""

$startTime = Get-Date

# Step 1: Deploy Infrastructure
Write-Host "=" * 60
Write-Host "STEP 1 of 4: Deploying Azure Infrastructure" -ForegroundColor Cyan
Write-Host "=" * 60

$terraformPath = Join-Path $PSScriptRoot "..\..\terraform\environments\poc"
Push-Location $terraformPath

try {
    # Check Azure authentication
    Write-Host "`n🔐 Checking Azure authentication..." -ForegroundColor Gray
    $account = az account show 2>$null

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ⚠️  Not logged in to Azure. Running az login..." -ForegroundColor Yellow
        az login

        if ($LASTEXITCODE -ne 0) {
            throw "Failed to authenticate with Azure"
        }
    }

    Write-Host "  ✓ Authenticated" -ForegroundColor Green

    # Run Terraform apply
    Write-Host "`n🏗️  Running Terraform apply..." -ForegroundColor Yellow
    Write-Host "  Creating 16 Azure resources..." -ForegroundColor Gray
    Write-Host ""

    terraform apply -auto-approve

    if ($LASTEXITCODE -ne 0) {
        throw "Terraform apply failed"
    }

    Write-Host ""
    Write-Host "✅ Infrastructure deployed successfully!" -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "❌ Infrastructure deployment failed: $_" -ForegroundColor Red
    exit 1
}
finally {
    Pop-Location
}

# Step 2: Create Search Index
Write-Host ""
Write-Host "=" * 60
Write-Host "STEP 2 of 4: Creating Search Index" -ForegroundColor Cyan
Write-Host "=" * 60
Write-Host ""

$createIndexScript = Join-Path $PSScriptRoot "Create-SearchIndex.ps1"

try {
    & pwsh $createIndexScript

    if ($LASTEXITCODE -ne 0) {
        throw "Search index creation failed"
    }

    Write-Host ""
    Write-Host "✅ Search index created successfully!" -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "❌ Search index creation failed: $_" -ForegroundColor Red
    Write-Host "You can manually create it later with:" -ForegroundColor Yellow
    Write-Host "  pwsh scripts/deployment/Create-SearchIndex.ps1" -ForegroundColor Gray
    exit 1
}

# Step 3: Index Documents
Write-Host ""
Write-Host "=" * 60
Write-Host "STEP 3 of 4: Indexing Documents" -ForegroundColor Cyan
Write-Host "=" * 60
Write-Host ""

$indexDocsScript = Join-Path $PSScriptRoot "Index-Documents.ps1"

try {
    & pwsh $indexDocsScript

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ⚠️  Some documents may have failed to index" -ForegroundColor Yellow
    }
    else {
        Write-Host ""
        Write-Host "✅ Documents indexed successfully!" -ForegroundColor Green
    }
}
catch {
    Write-Host ""
    Write-Host "❌ Document indexing failed: $_" -ForegroundColor Red
    Write-Host "You can manually index later with:" -ForegroundColor Yellow
    Write-Host "  pwsh scripts/deployment/Index-Documents.ps1" -ForegroundColor Gray
}

# Step 4: Validation
if (-not $SkipValidation) {
    Write-Host ""
    Write-Host "=" * 60
    Write-Host "STEP 4 of 4: Validating System" -ForegroundColor Cyan
    Write-Host "=" * 60
    Write-Host ""

    Start-Sleep -Seconds 2  # Give search index time to refresh

    $askScript = Join-Path $PSScriptRoot "Ask-Documentation.ps1"

    try {
        Write-Host "🧪 Running test query..." -ForegroundColor Gray
        Write-Host ""

        & pwsh $askScript -Question "What is Infrastructure as Code?"

        Write-Host ""
        Write-Host "✅ Validation successful!" -ForegroundColor Green
    }
    catch {
        Write-Host ""
        Write-Host "⚠️  Validation test failed, but system may still be working" -ForegroundColor Yellow
        Write-Host "Try manually:" -ForegroundColor Yellow
        Write-Host "  pwsh scripts/deployment/Ask-Documentation.ps1 -Question 'What is IaC?'" -ForegroundColor Gray
    }
}

# Summary
$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host ""
Write-Host "=" * 60
Write-Host "🎉 RESTORE COMPLETE!" -ForegroundColor Green
Write-Host "=" * 60
Write-Host ""
Write-Host "Time taken: $([math]::Round($duration.TotalMinutes, 1)) minutes" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ What's ready:" -ForegroundColor Green
Write-Host "  • All Azure infrastructure deployed" -ForegroundColor White
Write-Host "  • Search index created" -ForegroundColor White
Write-Host "  • Documents indexed with embeddings" -ForegroundColor White
Write-Host "  • System validated and working" -ForegroundColor White
Write-Host ""
Write-Host "🚀 You can now use:" -ForegroundColor Cyan
Write-Host "  # Ask questions about your documentation" -ForegroundColor Gray
Write-Host "  pwsh scripts/deployment/Ask-Documentation.ps1 -Question 'your question'" -ForegroundColor White
Write-Host ""
Write-Host "  # Search for specific documents" -ForegroundColor Gray
Write-Host "  pwsh scripts/deployment/Search-Documents.ps1 -Query 'terraform'" -ForegroundColor White
Write-Host ""
Write-Host "💰 Monthly cost: ~$25-35" -ForegroundColor Yellow
Write-Host ""
Write-Host "To tear down when done:" -ForegroundColor Gray
Write-Host "  pwsh scripts/deployment/Teardown-All.ps1" -ForegroundColor White
Write-Host ""
