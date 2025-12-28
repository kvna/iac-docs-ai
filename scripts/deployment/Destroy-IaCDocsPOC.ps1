<#
.SYNOPSIS
    Destroys the IaC Documentation POC infrastructure

.DESCRIPTION
    This script safely destroys all Azure resources created for the POC,
    including confirmation prompts and cost reporting.

.PARAMETER Environment
    The environment to destroy (default: poc)

.PARAMETER AutoApprove
    Skip confirmation prompts (use with extreme caution)

.PARAMETER KeepState
    Preserve Terraform state file (for recovery)

.EXAMPLE
    .\Destroy-IaCDocsPOC.ps1
    # Interactive destruction with confirmation

.EXAMPLE
    .\Destroy-IaCDocsPOC.ps1 -AutoApprove
    # Destroy without confirmation (DANGEROUS)

.NOTES
    Requires: PowerShell 7+, Azure CLI, Terraform 1.5+
    Author: IaC Team
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter()]
    [ValidateSet('poc', 'prod')]
    [string]$Environment = 'poc',

    [Parameter()]
    [switch]$AutoApprove,

    [Parameter()]
    [switch]$KeepState
)

#Requires -Version 7

$ErrorActionPreference = 'Stop'

##############################################################################
# Helper Functions
##############################################################################

function Write-Header {
    param([string]$Message)
    Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║ $($Message.PadRight(61)) ║" -ForegroundColor Red
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Red
}

function Write-Step {
    param([string]$Message)
    Write-Host "`n▶ $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

##############################################################################
# Main Destroy Logic
##############################################################################

try {
    Write-Header "⚠ WARNING: Resource Destruction ⚠"

    Write-Host "`nThis will PERMANENTLY DELETE all resources in the $Environment environment." -ForegroundColor Red
    Write-Host "This action CANNOT be undone.`n" -ForegroundColor Red

    # Navigate to Terraform directory
    $terraformDir = Join-Path $PSScriptRoot "..\..\terraform\environments\$Environment"
    if (-not (Test-Path $terraformDir)) {
        throw "Terraform directory not found: $terraformDir"
    }

    Push-Location $terraformDir

    try {
        # Check if state file exists
        if (-not (Test-Path ".terraform")) {
            Write-Warning-Custom "No Terraform state found. Run 'terraform init' first if you expect resources to exist."
            return
        }

        # Get list of resources to be destroyed
        Write-Step "Checking current infrastructure..."
        $stateOutput = terraform state list 2>&1

        if ($LASTEXITCODE -ne 0 -or -not $stateOutput) {
            Write-Warning-Custom "No resources found in state. Nothing to destroy."
            return
        }

        $resourceCount = ($stateOutput | Measure-Object).Count
        Write-Host "`nResources to be destroyed: $resourceCount" -ForegroundColor Red

        Write-Host "`nResource list:" -ForegroundColor Yellow
        $stateOutput | ForEach-Object {
            Write-Host "  - $_" -ForegroundColor Gray
        }

        # Get deployment info for final summary
        try {
            $outputJson = terraform output -json 2>$null | ConvertFrom-Json
            if ($outputJson) {
                Write-Host "`nCurrent deployment:" -ForegroundColor Yellow
                Write-Host "  Resource Group: $($outputJson.resource_group_name.value)" -ForegroundColor White
                Write-Host "  Location: $($outputJson.deployment_summary.value.location)" -ForegroundColor White
            }
        }
        catch {
            # Outputs might not be available
        }

        # Confirmation
        if (-not $AutoApprove) {
            Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Red
            Write-Host "║                    FINAL CONFIRMATION                         ║" -ForegroundColor Red
            Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Red

            Write-Host "`nAre you ABSOLUTELY SURE you want to destroy these resources?" -ForegroundColor Red
            Write-Host "Type 'destroy' to confirm: " -ForegroundColor Yellow -NoNewline
            $confirmation1 = Read-Host

            if ($confirmation1 -ne 'destroy') {
                Write-Host "`nDestruction cancelled. Resources preserved." -ForegroundColor Green
                return
            }

            Write-Host "`nType the environment name '$Environment' to proceed: " -ForegroundColor Yellow -NoNewline
            $confirmation2 = Read-Host

            if ($confirmation2 -ne $Environment) {
                Write-Host "`nDestruction cancelled. Resources preserved." -ForegroundColor Green
                return
            }
        }

        # Run destroy
        Write-Step "Destroying infrastructure..."
        Write-Host "This may take 5-10 minutes..." -ForegroundColor Gray

        $destroyArgs = @('destroy')
        if ($AutoApprove) {
            $destroyArgs += '-auto-approve'
        }

        terraform @destroyArgs

        if ($LASTEXITCODE -ne 0) {
            throw "Terraform destroy failed"
        }

        Write-Success "All resources destroyed successfully"

        # Clean up state (optional)
        if (-not $KeepState) {
            Write-Step "Cleaning up Terraform state..."

            if (Test-Path "terraform.tfstate") {
                Remove-Item "terraform.tfstate" -Force
            }
            if (Test-Path "terraform.tfstate.backup") {
                Remove-Item "terraform.tfstate.backup" -Force
            }
            if (Test-Path "tfplan") {
                Remove-Item "tfplan" -Force
            }

            Write-Success "State files cleaned up"
        }
        else {
            Write-Warning-Custom "State files preserved (use -KeepState was specified)"
        }

        Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║                  Destruction Complete                         ║" -ForegroundColor Green
        Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Green

        Write-Host "`nAll resources have been destroyed." -ForegroundColor Green
        Write-Host "Your Azure costs for this POC will stop accruing." -ForegroundColor Green

        if (-not $KeepState) {
            Write-Host "`nTo redeploy, run:" -ForegroundColor Cyan
            Write-Host "  .\scripts\deployment\Deploy-IaCDocsPOC.ps1" -ForegroundColor Gray
        }

    }
    finally {
        Pop-Location
    }
}
catch {
    Write-Host "`n✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nDestruction failed. Some resources may still exist." -ForegroundColor Yellow
    Write-Host "Check Azure Portal to verify resource status." -ForegroundColor Yellow
    exit 1
}
