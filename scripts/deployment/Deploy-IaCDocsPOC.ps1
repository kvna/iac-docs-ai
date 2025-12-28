<#
.SYNOPSIS
    Deploys the IaC Documentation AI Search POC infrastructure to Azure

.DESCRIPTION
    This script deploys the complete infrastructure for the IaC Documentation
    AI-powered search POC using Terraform. It handles:
    - Azure authentication
    - Terraform initialization and deployment
    - Post-deployment configuration
    - Cost estimation and deployment summary

.PARAMETER Environment
    The environment to deploy (default: poc)

.PARAMETER AutoApprove
    Skip Terraform approval prompt (use with caution)

.PARAMETER SearchSku
    Azure AI Search SKU: free, basic, or standard (default: free)

.PARAMETER PlanOnly
    Only run terraform plan, don't apply

.EXAMPLE
    .\Deploy-IaCDocsPOC.ps1
    # Interactive deployment with defaults

.EXAMPLE
    .\Deploy-IaCDocsPOC.ps1 -SearchSku basic -AutoApprove
    # Deploy with basic search tier, skip approval

.EXAMPLE
    .\Deploy-IaCDocsPOC.ps1 -PlanOnly
    # Preview changes without deploying

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
    [ValidateSet('free', 'basic', 'standard')]
    [string]$SearchSku = 'free',

    [Parameter()]
    [switch]$PlanOnly,

    [Parameter()]
    [string]$Owner = $env:USER
)

#Requires -Version 7

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

##############################################################################
# Helper Functions
##############################################################################

function Write-Header {
    param([string]$Message)
    Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║ $($Message.PadRight(61)) ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Message)
    Write-Host "`n▶ $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Test-Prerequisites {
    Write-Step "Checking prerequisites..."

    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        throw "PowerShell 7 or higher is required. Current version: $($PSVersionTable.PSVersion)"
    }
    Write-Success "PowerShell $($PSVersionTable.PSVersion)"

    # Check Azure CLI
    try {
        $azVersion = (az version --output json | ConvertFrom-Json).'azure-cli'
        Write-Success "Azure CLI $azVersion"
    }
    catch {
        throw "Azure CLI is not installed or not in PATH. Install from: https://aka.ms/installazurecli"
    }

    # Check Terraform
    try {
        $tfOutput = terraform version -json | ConvertFrom-Json
        $tfVersion = $tfOutput.terraform_version
        Write-Success "Terraform $tfVersion"

        if ([version]$tfVersion -lt [version]"1.5.0") {
            throw "Terraform 1.5.0 or higher is required. Current version: $tfVersion"
        }
    }
    catch {
        throw "Terraform is not installed or not in PATH. Install from: https://www.terraform.io/downloads"
    }

    # Check Azure authentication
    try {
        $account = az account show --output json | ConvertFrom-Json
        Write-Success "Authenticated to Azure subscription: $($account.name)"
        return $account
    }
    catch {
        throw "Not authenticated to Azure. Run 'az login' first."
    }
}

function Get-EstimatedCost {
    param([string]$SearchSku)

    $costs = @{
        'free' = @{
            'Search' = 0
            'OpenAI' = 10
            'Storage' = 1
            'FunctionApp' = 0
            'Total' = 11
        }
        'basic' = @{
            'Search' = 75
            'OpenAI' = 10
            'Storage' = 1
            'FunctionApp' = 0
            'Total' = 86
        }
        'standard' = @{
            'Search' = 250
            'OpenAI' = 10
            'Storage' = 1
            'FunctionApp' = 13
            'Total' = 274
        }
    }

    return $costs[$SearchSku]
}

function Show-DeploymentSummary {
    param(
        [object]$TerraformOutput,
        [string]$SearchSku
    )

    $costs = Get-EstimatedCost -SearchSku $SearchSku

    Write-Header "Deployment Summary"

    Write-Host "`nDeployed Resources:" -ForegroundColor Cyan
    Write-Host "  Resource Group:  " -NoNewline
    Write-Host $TerraformOutput.resource_group_name.value -ForegroundColor White
    Write-Host "  Location:        " -NoNewline
    Write-Host $TerraformOutput.deployment_summary.value.location -ForegroundColor White
    Write-Host "  Search Service:  " -NoNewline
    Write-Host "$($TerraformOutput.search_service_name.value) (SKU: $SearchSku)" -ForegroundColor White
    Write-Host "  OpenAI Service:  " -NoNewline
    Write-Host $TerraformOutput.openai_endpoint.value -ForegroundColor White
    Write-Host "  Function App:    " -NoNewline
    Write-Host $TerraformOutput.function_app_default_hostname.value -ForegroundColor White
    Write-Host "  Storage:         " -NoNewline
    Write-Host $TerraformOutput.storage_account_name.value -ForegroundColor White
    Write-Host "  Key Vault:       " -NoNewline
    Write-Host $TerraformOutput.key_vault_name.value -ForegroundColor White

    Write-Host "`nEstimated Monthly Cost:" -ForegroundColor Cyan
    Write-Host "  AI Search:       " -NoNewline
    Write-Host "`$$($costs.Search)" -ForegroundColor $(if ($costs.Search -eq 0) { 'Green' } else { 'Yellow' })
    Write-Host "  Azure OpenAI:    " -NoNewline
    Write-Host "`$$($costs.OpenAI)" -ForegroundColor Yellow
    Write-Host "  Storage:         " -NoNewline
    Write-Host "`$$($costs.Storage)" -ForegroundColor Green
    Write-Host "  Function App:    " -NoNewline
    Write-Host "`$$($costs.FunctionApp)" -ForegroundColor Green
    Write-Host "  ─────────────────────" -ForegroundColor Gray
    Write-Host "  Total (approx):  " -NoNewline
    Write-Host "`$$($costs.Total)/month" -ForegroundColor $(if ($costs.Total -lt 50) { 'Green' } elseif ($costs.Total -lt 150) { 'Yellow' } else { 'Red' })

    Write-Host "`nNext Steps:" -ForegroundColor Cyan
    Write-Host "  1. Upload documentation:" -ForegroundColor White
    Write-Host "     .\scripts\deployment\Upload-Documents.ps1" -ForegroundColor Gray
    Write-Host "  2. Test search functionality:" -ForegroundColor White
    Write-Host "     .\scripts\testing\Test-SearchQuality.ps1" -ForegroundColor Gray
    Write-Host "  3. Access Function App:" -ForegroundColor White
    Write-Host "     https://$($TerraformOutput.function_app_default_hostname.value)" -ForegroundColor Gray
    Write-Host "  4. When done, destroy resources:" -ForegroundColor White
    Write-Host "     .\scripts\deployment\Destroy-IaCDocsPOC.ps1" -ForegroundColor Gray
}

##############################################################################
# Main Deployment Logic
##############################################################################

try {
    Write-Header "IaC Documentation POC - Deployment"

    # Step 1: Prerequisites
    $account = Test-Prerequisites

    # Step 2: Navigate to Terraform directory
    $terraformDir = Join-Path $PSScriptRoot "..\..\terraform\environments\$Environment"
    if (-not (Test-Path $terraformDir)) {
        throw "Terraform directory not found: $terraformDir"
    }

    Write-Step "Changing to Terraform directory: $terraformDir"
    Push-Location $terraformDir

    try {
        # Step 3: Create tfvars file if it doesn't exist
        if (-not (Test-Path "terraform.tfvars")) {
            Write-Step "Creating terraform.tfvars from example..."

            $tfvarsContent = Get-Content "terraform.tfvars.example" -Raw
            $tfvarsContent = $tfvarsContent -replace 'your\.email@company\.com', $account.user.name
            $tfvarsContent = $tfvarsContent -replace 'search_sku = "free"', "search_sku = `"$SearchSku`""

            Set-Content -Path "terraform.tfvars" -Value $tfvarsContent
            Write-Success "Created terraform.tfvars"
        }
        else {
            Write-Success "Using existing terraform.tfvars"
        }

        # Step 4: Terraform Init
        Write-Step "Initializing Terraform..."
        $initOutput = terraform init -upgrade 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Terraform init failed:`n$initOutput"
        }
        Write-Success "Terraform initialized"

        # Step 5: Terraform Validate
        Write-Step "Validating Terraform configuration..."
        $validateOutput = terraform validate -json | ConvertFrom-Json
        if (-not $validateOutput.valid) {
            throw "Terraform validation failed: $($validateOutput.error_message)"
        }
        Write-Success "Configuration is valid"

        # Step 6: Terraform Plan
        Write-Step "Creating deployment plan..."
        $planArgs = @('plan', '-out=tfplan', '-input=false')

        if ($AutoApprove) {
            $planArgs += '-detailed-exitcode'
        }

        terraform @planArgs
        $planExitCode = $LASTEXITCODE

        if ($planExitCode -eq 1) {
            throw "Terraform plan failed"
        }
        elseif ($planExitCode -eq 2) {
            Write-Success "Plan created - changes detected"
        }
        elseif ($planExitCode -eq 0) {
            Write-Success "Plan created - no changes needed"

            if (-not $PlanOnly) {
                Write-Host "`nNo infrastructure changes required." -ForegroundColor Green
                return
            }
        }

        if ($PlanOnly) {
            Write-Success "Plan-only mode - stopping before apply"
            Write-Host "`nTo apply these changes, run without -PlanOnly flag" -ForegroundColor Yellow
            return
        }

        # Step 7: Confirm deployment
        if (-not $AutoApprove) {
            Write-Host "`n" -NoNewline
            $costs = Get-EstimatedCost -SearchSku $SearchSku
            Write-Host "Estimated monthly cost: `$$($costs.Total)" -ForegroundColor Yellow

            Write-Host "`nDo you want to proceed with deployment? (yes/no): " -ForegroundColor Cyan -NoNewline
            $confirmation = Read-Host

            if ($confirmation -ne 'yes') {
                Write-Host "Deployment cancelled." -ForegroundColor Yellow
                return
            }
        }

        # Step 8: Terraform Apply
        Write-Step "Deploying infrastructure..."
        Write-Host "This may take 5-10 minutes..." -ForegroundColor Gray

        terraform apply tfplan

        if ($LASTEXITCODE -ne 0) {
            throw "Terraform apply failed"
        }

        Write-Success "Infrastructure deployed successfully"

        # Step 9: Get outputs
        Write-Step "Retrieving deployment information..."
        $outputJson = terraform output -json | ConvertFrom-Json

        # Step 10: Show summary
        Show-DeploymentSummary -TerraformOutput $outputJson -SearchSku $SearchSku

        Write-Host "`n"
        Write-Success "Deployment complete!"

    }
    finally {
        Pop-Location
    }
}
catch {
    Write-Error-Custom $_.Exception.Message
    Write-Host "`nDeployment failed. Check the error message above." -ForegroundColor Red
    exit 1
}
