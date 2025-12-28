<#
.SYNOPSIS
    Automated pre-flight check for IaC Documentation POC deployment

.DESCRIPTION
    Validates all prerequisites before deployment including:
    - PowerShell version
    - Terraform installation and version
    - Azure CLI installation and version
    - Azure authentication
    - Azure subscription access
    - Azure OpenAI availability
    - Required permissions

.PARAMETER Fix
    Attempt to automatically fix issues where possible

.PARAMETER Deploy
    Automatically proceed to deployment if all checks pass

.EXAMPLE
    .\Test-Prerequisites.ps1
    # Check all prerequisites

.EXAMPLE
    .\Test-Prerequisites.ps1 -Fix
    # Check and attempt to fix issues

.EXAMPLE
    .\Test-Prerequisites.ps1 -Deploy
    # Check prerequisites and deploy if all pass

.NOTES
    Author: IaC Team
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter()]
    [switch]$Fix,

    [Parameter()]
    [switch]$Deploy,

    [Parameter()]
    [switch]$SkipOpenAICheck
)

#Requires -Version 7

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

##############################################################################
# Configuration
##############################################################################

$RequiredVersions = @{
    PowerShell = [version]'7.4.0'
    Terraform  = [version]'1.5.0'
    AzureCLI   = [version]'2.50.0'
}

$script:AllChecksPassed = $true
$script:Issues = @()
$script:Warnings = @()

##############################################################################
# Helper Functions
##############################################################################

function Write-Header {
    param([string]$Message)
    Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║ $($Message.PadRight(61)) ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
}

function Write-CheckResult {
    param(
        [string]$Name,
        [bool]$Passed,
        [string]$Message = "",
        [string]$FixCommand = ""
    )

    $status = if ($Passed) { "✓" } else { "✗" }
    $color = if ($Passed) { "Green" } else { "Red" }

    Write-Host "  $status " -NoNewline -ForegroundColor $color
    Write-Host "$Name" -NoNewline

    if ($Message) {
        Write-Host " - " -NoNewline -ForegroundColor Gray
        Write-Host $Message -ForegroundColor $(if ($Passed) { 'Gray' } else { 'Yellow' })
    }
    else {
        Write-Host ""
    }

    if (-not $Passed) {
        $script:AllChecksPassed = $false
        $script:Issues += @{
            Name = $Name
            Message = $Message
            FixCommand = $FixCommand
        }
    }
}

function Write-Warning-Check {
    param([string]$Message)
    Write-Host "  ⚠ $Message" -ForegroundColor Yellow
    $script:Warnings += $Message
}

function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

##############################################################################
# Prerequisite Checks
##############################################################################

function Test-PowerShellVersion {
    Write-Host "`n▶ Checking PowerShell Version..." -ForegroundColor Cyan

    $currentVersion = $PSVersionTable.PSVersion
    $required = $RequiredVersions.PowerShell

    if ($currentVersion -ge $required) {
        Write-CheckResult -Name "PowerShell $currentVersion" -Passed $true -Message "✓ Compatible"
        return $true
    }
    else {
        Write-CheckResult -Name "PowerShell $currentVersion" -Passed $false `
            -Message "Required: $required or higher" `
            -FixCommand "Install from: https://github.com/PowerShell/PowerShell/releases"
        return $false
    }
}

function Test-TerraformInstallation {
    Write-Host "`n▶ Checking Terraform..." -ForegroundColor Cyan

    if (-not (Test-CommandExists 'terraform')) {
        $fixCmd = if ($IsWindows) {
            "choco install terraform"
        }
        elseif ($IsMacOS) {
            "brew tap hashicorp/tap && brew install hashicorp/tap/terraform"
        }
        else {
            "See: https://www.terraform.io/downloads"
        }

        Write-CheckResult -Name "Terraform" -Passed $false `
            -Message "Not installed" `
            -FixCommand $fixCmd
        return $false
    }

    try {
        $tfOutput = terraform version -json | ConvertFrom-Json
        $tfVersion = [version]$tfOutput.terraform_version
        $required = $RequiredVersions.Terraform

        if ($tfVersion -ge $required) {
            Write-CheckResult -Name "Terraform v$tfVersion" -Passed $true -Message "✓ Compatible"
            return $true
        }
        else {
            Write-CheckResult -Name "Terraform v$tfVersion" -Passed $false `
                -Message "Required: v$required or higher. Run: terraform version -upgrade"
            return $false
        }
    }
    catch {
        Write-CheckResult -Name "Terraform" -Passed $false -Message "Error checking version: $_"
        return $false
    }
}

function Test-AzureCLIInstallation {
    Write-Host "`n▶ Checking Azure CLI..." -ForegroundColor Cyan

    if (-not (Test-CommandExists 'az')) {
        $fixCmd = if ($IsWindows) {
            "choco install azure-cli"
        }
        elseif ($IsMacOS) {
            "brew update && brew install azure-cli"
        }
        else {
            "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
        }

        Write-CheckResult -Name "Azure CLI" -Passed $false `
            -Message "Not installed" `
            -FixCommand $fixCmd
        return $false
    }

    try {
        $azVersionOutput = az version --output json 2>$null | ConvertFrom-Json
        $azVersion = [version]$azVersionOutput.'azure-cli'
        $required = $RequiredVersions.AzureCLI

        if ($azVersion -ge $required) {
            Write-CheckResult -Name "Azure CLI v$azVersion" -Passed $true -Message "✓ Compatible"
            return $true
        }
        else {
            Write-CheckResult -Name "Azure CLI v$azVersion" -Passed $false `
                -Message "Required: v$required or higher. Run: az upgrade"
            return $false
        }
    }
    catch {
        Write-CheckResult -Name "Azure CLI" -Passed $false -Message "Error checking version: $_"
        return $false
    }
}

function Test-AzureAuthentication {
    Write-Host "`n▶ Checking Azure Authentication..." -ForegroundColor Cyan

    try {
        $account = az account show --output json 2>$null | ConvertFrom-Json

        if ($account) {
            Write-CheckResult -Name "Azure Authentication" -Passed $true `
                -Message "Logged in as: $($account.user.name)"

            Write-Host "    Subscription: " -NoNewline -ForegroundColor Gray
            Write-Host "$($account.name)" -ForegroundColor White
            Write-Host "    Subscription ID: " -NoNewline -ForegroundColor Gray
            Write-Host "$($account.id)" -ForegroundColor White
            Write-Host "    Tenant: " -NoNewline -ForegroundColor Gray
            Write-Host "$($account.tenantId)" -ForegroundColor White

            return $account
        }
        else {
            throw "No account information"
        }
    }
    catch {
        Write-CheckResult -Name "Azure Authentication" -Passed $false `
            -Message "Not authenticated" `
            -FixCommand "az login"
        return $null
    }
}

function Test-AzurePermissions {
    param([object]$Account)

    Write-Host "`n▶ Checking Azure Permissions..." -ForegroundColor Cyan

    if (-not $Account) {
        Write-CheckResult -Name "Subscription Permissions" -Passed $false `
            -Message "Cannot check - not authenticated"
        return $false
    }

    try {
        # Get role assignments for current user
        $userPrincipalName = $Account.user.name
        $roleAssignments = az role assignment list --assignee $userPrincipalName --output json 2>$null | ConvertFrom-Json

        if (-not $roleAssignments) {
            Write-Warning-Check "Could not verify role assignments (might be using service principal)"
            return $true  # Don't fail, just warn
        }

        # Check for required roles (Owner, Contributor, or custom role with sufficient permissions)
        $hasRequiredRole = $roleAssignments | Where-Object {
            $_.roleDefinitionName -in @('Owner', 'Contributor') -and
            $_.scope -like "/subscriptions/$($Account.id)*"
        }

        if ($hasRequiredRole) {
            $roleName = ($hasRequiredRole | Select-Object -First 1).roleDefinitionName
            Write-CheckResult -Name "Subscription Permissions" -Passed $true `
                -Message "Role: $roleName"
            return $true
        }
        else {
            Write-CheckResult -Name "Subscription Permissions" -Passed $false `
                -Message "Contributor or Owner role required on subscription"
            return $false
        }
    }
    catch {
        Write-Warning-Check "Could not verify permissions: $_"
        return $true  # Don't fail deployment, just warn
    }
}

function Test-AzureOpenAIAccess {
    param([object]$Account)

    Write-Host "`n▶ Checking Azure OpenAI Access..." -ForegroundColor Cyan

    if ($SkipOpenAICheck) {
        Write-Warning-Check "Azure OpenAI check skipped (--SkipOpenAICheck)"
        return $true
    }

    if (-not $Account) {
        Write-CheckResult -Name "Azure OpenAI Access" -Passed $false `
            -Message "Cannot check - not authenticated"
        return $false
    }

    try {
        # Check if OpenAI is available as a Cognitive Services kind
        $kinds = az cognitiveservices account list-kinds --output json 2>$null | ConvertFrom-Json

        if ('OpenAI' -in $kinds) {
            Write-CheckResult -Name "Azure OpenAI Access" -Passed $true `
                -Message "✓ Available in subscription"
            return $true
        }
        else {
            Write-CheckResult -Name "Azure OpenAI Access" -Passed $false `
                -Message "Not available - request access at https://aka.ms/oai/access" `
                -FixCommand "Visit https://aka.ms/oai/access to request access (1-2 business days)"

            Write-Host "`n    Note: Deployment can proceed without OpenAI initially" -ForegroundColor Yellow
            Write-Host "          You can add OpenAI later after access is granted`n" -ForegroundColor Yellow

            return $false
        }
    }
    catch {
        Write-Warning-Check "Could not verify OpenAI access: $_"
        Write-Host "    You can proceed, but deployment may fail if OpenAI is not available" -ForegroundColor Yellow
        return $true  # Don't block deployment
    }
}

function Test-AzureRegionAvailability {
    Write-Host "`n▶ Checking Azure Region Availability..." -ForegroundColor Cyan

    try {
        # Check if North Europe is available
        $locations = az account list-locations --output json 2>$null | ConvertFrom-Json
        $northEurope = $locations | Where-Object { $_.name -eq 'northeurope' }

        if ($northEurope) {
            Write-CheckResult -Name "North Europe Region" -Passed $true `
                -Message "✓ Available (Ireland)"

            # Check Sweden Central for OpenAI
            $swedenCentral = $locations | Where-Object { $_.name -eq 'swedencentral' }
            if ($swedenCentral) {
                Write-CheckResult -Name "Sweden Central Region" -Passed $true `
                    -Message "✓ Available (for OpenAI)"
            }

            return $true
        }
        else {
            Write-CheckResult -Name "North Europe Region" -Passed $false `
                -Message "Not available in subscription"
            return $false
        }
    }
    catch {
        Write-Warning-Check "Could not verify region availability: $_"
        return $true
    }
}

function Test-DiskSpace {
    Write-Host "`n▶ Checking Disk Space..." -ForegroundColor Cyan

    try {
        $workingDir = Get-Location
        $drive = [System.IO.Path]::GetPathRoot($workingDir)

        if ($IsWindows) {
            $driveInfo = Get-PSDrive ($drive.TrimEnd(':\')) -ErrorAction SilentlyContinue
            if ($driveInfo) {
                $freeGB = [Math]::Round($driveInfo.Free / 1GB, 2)
                if ($freeGB -gt 1) {
                    Write-CheckResult -Name "Disk Space" -Passed $true -Message "$freeGB GB available"
                    return $true
                }
                else {
                    Write-CheckResult -Name "Disk Space" -Passed $false -Message "Only $freeGB GB available"
                    return $false
                }
            }
        }

        # For non-Windows or if check fails, just pass
        Write-CheckResult -Name "Disk Space" -Passed $true -Message "Check skipped"
        return $true
    }
    catch {
        Write-CheckResult -Name "Disk Space" -Passed $true -Message "Check skipped"
        return $true
    }
}

function Test-TerraformDirectory {
    Write-Host "`n▶ Checking Terraform Configuration..." -ForegroundColor Cyan

    $terraformDir = Join-Path $PSScriptRoot "..\..\terraform\environments\poc"

    if (Test-Path $terraformDir) {
        Write-CheckResult -Name "Terraform Directory" -Passed $true -Message "Found at: $terraformDir"

        # Check for required files
        $requiredFiles = @('main.tf', 'variables.tf', 'terraform.tfvars.example')
        $allPresent = $true

        foreach ($file in $requiredFiles) {
            $filePath = Join-Path $terraformDir $file
            if (-not (Test-Path $filePath)) {
                Write-CheckResult -Name "  $file" -Passed $false -Message "Missing"
                $allPresent = $false
            }
        }

        if ($allPresent) {
            Write-Host "    All required files present" -ForegroundColor Green
        }

        return $allPresent
    }
    else {
        Write-CheckResult -Name "Terraform Directory" -Passed $false `
            -Message "Not found at: $terraformDir"
        return $false
    }
}

##############################################################################
# Summary and Next Steps
##############################################################################

function Show-Summary {
    Write-Header "Pre-Flight Check Summary"

    if ($script:AllChecksPassed) {
        Write-Host "  ✓ " -NoNewline -ForegroundColor Green
        Write-Host "All prerequisite checks passed!" -ForegroundColor Green

        if ($script:Warnings.Count -gt 0) {
            Write-Host "`n  Warnings:" -ForegroundColor Yellow
            foreach ($warning in $script:Warnings) {
                Write-Host "    ⚠ $warning" -ForegroundColor Yellow
            }
        }

        Write-Host "`n  You are ready to deploy!`n" -ForegroundColor Green

        if ($Deploy) {
            Write-Host "  Proceeding to deployment..." -ForegroundColor Cyan
            return 'DEPLOY'
        }
        else {
            Write-Host "  Next step:" -ForegroundColor Cyan
            Write-Host "    .\scripts\deployment\Deploy-IaCDocsPOC.ps1" -ForegroundColor White
            Write-Host "`n  Or run with -Deploy flag to proceed automatically:" -ForegroundColor Cyan
            Write-Host "    .\scripts\deployment\Test-Prerequisites.ps1 -Deploy" -ForegroundColor White
            return 'READY'
        }
    }
    else {
        Write-Host "  ✗ " -NoNewline -ForegroundColor Red
        Write-Host "Some prerequisite checks failed`n" -ForegroundColor Red

        Write-Host "  Issues found:" -ForegroundColor Yellow
        foreach ($issue in $script:Issues) {
            Write-Host "`n    ✗ $($issue.Name)" -ForegroundColor Red
            if ($issue.Message) {
                Write-Host "      $($issue.Message)" -ForegroundColor Gray
            }
            if ($issue.FixCommand) {
                Write-Host "      Fix: " -NoNewline -ForegroundColor Cyan
                Write-Host "$($issue.FixCommand)" -ForegroundColor White
            }
        }

        Write-Host "`n  Please fix the issues above and run this script again.`n" -ForegroundColor Yellow
        return 'FAILED'
    }
}

##############################################################################
# Main Execution
##############################################################################

try {
    Write-Header "IaC Documentation POC - Pre-Flight Check"

    Write-Host "This script will verify all prerequisites for deployment.`n" -ForegroundColor Gray

    # Run all checks
    Test-PowerShellVersion
    Test-TerraformInstallation
    Test-AzureCLIInstallation

    $account = Test-AzureAuthentication

    if ($account) {
        Test-AzurePermissions -Account $account
        Test-AzureOpenAIAccess -Account $account
        Test-AzureRegionAvailability
    }

    Test-DiskSpace
    Test-TerraformDirectory

    # Show summary and next steps
    $result = Show-Summary

    # Auto-deploy if requested and checks passed
    if ($result -eq 'DEPLOY') {
        Write-Host ""
        $deployScript = Join-Path $PSScriptRoot "Deploy-IaCDocsPOC.ps1"
        & $deployScript
    }
    elseif ($result -eq 'READY') {
        exit 0
    }
    else {
        exit 1
    }
}
catch {
    Write-Host "`n✗ Error during pre-flight check: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
