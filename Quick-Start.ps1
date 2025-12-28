<#
.SYNOPSIS
    One-command setup and deployment for IaC Documentation POC

.DESCRIPTION
    This script automates the entire process:
    1. Checks all prerequisites
    2. Offers to fix common issues
    3. Deploys to Azure if everything is ready
    4. Shows you what was created

.PARAMETER SkipPrereqCheck
    Skip prerequisite checking (not recommended)

.PARAMETER AutoApprove
    Skip all confirmation prompts (use with caution)

.EXAMPLE
    .\Quick-Start.ps1
    # Interactive setup and deployment

.EXAMPLE
    .\Quick-Start.ps1 -AutoApprove
    # Fully automated (use for CI/CD)

.NOTES
    This is the easiest way to get started!
    Author: IaC Team
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter()]
    [switch]$SkipPrereqCheck,

    [Parameter()]
    [switch]$AutoApprove
)

#Requires -Version 7

$ErrorActionPreference = 'Stop'

##############################################################################
# Welcome
##############################################################################

function Show-Welcome {
    Clear-Host
    Write-Host @"

╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║        IaC Documentation Modernization & AI Search            ║
║                     Quick Start Guide                         ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

Welcome! This script will:

  1. ✓ Check all prerequisites (Terraform, Azure CLI, etc.)
  2. ✓ Verify Azure access and permissions
  3. ✓ Deploy the POC to Azure (~5-10 minutes)
  4. ✓ Show you what was created
  5. ✓ Explain next steps

Estimated time: 15 minutes
Estimated cost: ~`$12/month (can be destroyed anytime)

"@ -ForegroundColor Cyan

    if (-not $AutoApprove) {
        Write-Host "Ready to begin? (y/n): " -ForegroundColor Yellow -NoNewline
        $response = Read-Host

        if ($response -ne 'y') {
            Write-Host "`nNo problem! When you're ready, run this script again." -ForegroundColor Green
            Write-Host "Or read the proposal first: " -NoNewline
            Write-Host "cat IaC_Documentation_Modernization_Proposal.md`n" -ForegroundColor White
            exit 0
        }
    }

    Write-Host "`nLet's get started!`n" -ForegroundColor Green
}

##############################################################################
# Step-by-Step Execution
##############################################################################

function Invoke-PrerequisiteCheck {
    Write-Host "`n" -NoNewline
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host " Step 1: Prerequisite Check" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

    $prereqScript = Join-Path $PSScriptRoot "scripts\deployment\Test-Prerequisites.ps1"

    if (-not (Test-Path $prereqScript)) {
        Write-Host "✗ Cannot find prerequisite check script" -ForegroundColor Red
        Write-Host "  Expected: $prereqScript" -ForegroundColor Yellow
        return $false
    }

    try {
        & $prereqScript

        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n✓ All prerequisites met!" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "`n✗ Some prerequisites failed." -ForegroundColor Red
            Write-Host "`nPlease fix the issues above and run this script again." -ForegroundColor Yellow
            Write-Host "Or get help: open an issue or contact the team.`n" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "`n✗ Error during prerequisite check: $_" -ForegroundColor Red
        return $false
    }
}

function Invoke-Deployment {
    Write-Host "`n" -NoNewline
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host " Step 2: Deploying to Azure" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

    $deployScript = Join-Path $PSScriptRoot "scripts\deployment\Deploy-IaCDocsPOC.ps1"

    if (-not (Test-Path $deployScript)) {
        Write-Host "✗ Cannot find deployment script" -ForegroundColor Red
        return $false
    }

    try {
        $deployArgs = @()
        if ($AutoApprove) {
            $deployArgs += '-AutoApprove'
        }

        & $deployScript @deployArgs

        if ($LASTEXITCODE -eq 0) {
            return $true
        }
        else {
            Write-Host "`n✗ Deployment failed. Check errors above." -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "`n✗ Deployment error: $_" -ForegroundColor Red
        return $false
    }
}

function Show-NextSteps {
    Write-Host "`n" -NoNewline
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host " 🎉 Success! What's Next?" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════`n" -ForegroundColor Green

    Write-Host "Your IaC Documentation POC is now running in Azure!`n" -ForegroundColor White

    Write-Host "Here's what you can do now:" -ForegroundColor Cyan

    Write-Host "`n1. " -NoNewline -ForegroundColor Yellow
    Write-Host "Test Document Quality Validation:" -ForegroundColor White
    Write-Host "   pwsh ./scripts/validation/Test-DocumentQuality.ps1 -Path ./docs" -ForegroundColor Gray

    Write-Host "`n2. " -NoNewline -ForegroundColor Yellow
    Write-Host "Explore Sample Documentation:" -ForegroundColor White
    Write-Host "   cat docs/day1/concept-iac-overview.md" -ForegroundColor Gray
    Write-Host "   cat docs/reference/reference-naming-conventions.md" -ForegroundColor Gray

    Write-Host "`n3. " -NoNewline -ForegroundColor Yellow
    Write-Host "Review the Documentation System:" -ForegroundColor White
    Write-Host "   cat DOCUMENTATION_SYSTEM_GUIDE.md" -ForegroundColor Gray

    Write-Host "`n4. " -NoNewline -ForegroundColor Yellow
    Write-Host "Check Azure Portal:" -ForegroundColor White
    Write-Host "   Visit: https://portal.azure.com" -ForegroundColor Gray
    Write-Host "   Search for: rg-iac-docs-poc-northeu" -ForegroundColor Gray

    Write-Host "`n5. " -NoNewline -ForegroundColor Yellow
    Write-Host "Upload Documents to Search (coming soon):" -ForegroundColor White
    Write-Host "   pwsh ./scripts/deployment/Upload-Documents.ps1" -ForegroundColor Gray

    Write-Host "`n" -NoNewline
    Write-Host "⚠  IMPORTANT: " -NoNewline -ForegroundColor Red
    Write-Host "When you're done testing, destroy resources to stop costs:" -ForegroundColor Yellow
    Write-Host "   pwsh ./scripts/deployment/Destroy-IaCDocsPOC.ps1`n" -ForegroundColor White

    Write-Host "Current monthly cost: ~`$12 (destroy anytime to stop)`n" -ForegroundColor Cyan

    Write-Host "Questions? Check the README.md or open an issue!`n" -ForegroundColor Gray
}

##############################################################################
# Main Execution
##############################################################################

try {
    # Step 0: Welcome
    Show-Welcome

    # Step 1: Prerequisite Check
    if (-not $SkipPrereqCheck) {
        $prereqPassed = Invoke-PrerequisiteCheck

        if (-not $prereqPassed) {
            Write-Host "`nExiting. Please fix prerequisites and try again.`n" -ForegroundColor Yellow
            exit 1
        }

        Start-Sleep -Seconds 2
    }
    else {
        Write-Host "⚠ Skipping prerequisite check (not recommended)`n" -ForegroundColor Yellow
    }

    # Step 2: Deployment
    $deploymentSucceeded = Invoke-Deployment

    if (-not $deploymentSucceeded) {
        Write-Host "`nDeployment failed. Check errors above.`n" -ForegroundColor Red
        exit 1
    }

    # Step 3: Success & Next Steps
    Show-NextSteps

    exit 0
}
catch {
    Write-Host "`n✗ Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nStack trace:" -ForegroundColor Gray
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray
    exit 1
}
