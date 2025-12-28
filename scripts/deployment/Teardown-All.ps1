<#
.SYNOPSIS
    Tears down all Azure resources for the POC

.DESCRIPTION
    Destroys all Azure resources using Terraform to stop all costs.
    Your code, documents, and configuration files remain on your computer.

.PARAMETER SkipConfirmation
    Skip the confirmation prompt (use with caution)

.EXAMPLE
    .\Teardown-All.ps1

.EXAMPLE
    .\Teardown-All.ps1 -SkipConfirmation

.NOTES
    Requires: PowerShell 7+, Terraform, Azure CLI
#>

[CmdletBinding()]
param (
    [Parameter()]
    [switch]$SkipConfirmation
)

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "🗑️  TEARDOWN ALL RESOURCES" -ForegroundColor Red
Write-Host "=" * 60

# Show what will be deleted
Write-Host "`n📋 Resources to be deleted:" -ForegroundColor Yellow
Write-Host "  • Resource Group: rg-iac-docs-poc-northeu" -ForegroundColor Gray
Write-Host "  • Azure AI Search" -ForegroundColor Gray
Write-Host "  • Azure OpenAI Service" -ForegroundColor Gray
Write-Host "  • Storage Account" -ForegroundColor Gray
Write-Host "  • Key Vault" -ForegroundColor Gray
Write-Host "  • Application Insights" -ForegroundColor Gray
Write-Host "  • Log Analytics" -ForegroundColor Gray
Write-Host "  • All indexed documents and search data" -ForegroundColor Gray

Write-Host "`n✅ What remains on your computer:" -ForegroundColor Green
Write-Host "  • All code and scripts" -ForegroundColor Gray
Write-Host "  • Documentation files (docs/*.md)" -ForegroundColor Gray
Write-Host "  • Terraform configuration" -ForegroundColor Gray
Write-Host "  • Terraform state (for recreation)" -ForegroundColor Gray

Write-Host "`n💰 Cost Impact:" -ForegroundColor Cyan
Write-Host "  Current: ~$25-35/month" -ForegroundColor Gray
Write-Host "  After teardown: $0/month" -ForegroundColor Green

# Confirmation
if (-not $SkipConfirmation) {
    Write-Host ""
    Write-Host "⚠️  WARNING: This will delete all Azure resources!" -ForegroundColor Yellow
    Write-Host "You can recreate everything with Restore-All.ps1" -ForegroundColor Yellow
    Write-Host ""

    $confirmation = Read-Host "Type 'yes' to continue"

    if ($confirmation -ne 'yes') {
        Write-Host "`n❌ Teardown cancelled" -ForegroundColor Yellow
        exit 0
    }
}

# Navigate to Terraform directory
$terraformPath = Join-Path $PSScriptRoot "..\..\terraform\environments\poc"
Write-Host "`n📂 Navigating to Terraform directory..." -ForegroundColor Gray
Push-Location $terraformPath

try {
    # Check if we're logged in to Azure
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

    # Run Terraform destroy
    Write-Host "`n🔥 Running Terraform destroy..." -ForegroundColor Yellow
    Write-Host "  This may take 5-15 minutes (Key Vault takes longest)" -ForegroundColor Gray
    Write-Host ""

    terraform destroy -auto-approve

    if ($LASTEXITCODE -ne 0) {
        throw "Terraform destroy failed"
    }

    Write-Host ""
    Write-Host "=" * 60
    Write-Host "✅ TEARDOWN COMPLETE!" -ForegroundColor Green
    Write-Host ""
    Write-Host "All Azure resources have been deleted." -ForegroundColor White
    Write-Host "Costs stopped: You are no longer being charged." -ForegroundColor Green
    Write-Host ""
    Write-Host "To recreate everything, run:" -ForegroundColor Yellow
    Write-Host "  pwsh scripts/deployment/Restore-All.ps1" -ForegroundColor Cyan
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Host "❌ Teardown failed: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "You can try manual cleanup:" -ForegroundColor Yellow
    Write-Host "  az group delete --name rg-iac-docs-poc-northeu --yes" -ForegroundColor Gray
    exit 1
}
finally {
    Pop-Location
}
