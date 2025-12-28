<#
.SYNOPSIS
    Uploads documentation to Azure Blob Storage

.DESCRIPTION
    This script uploads all markdown documentation files to Azure Blob Storage
    for indexing and search.

.PARAMETER ResourceGroupName
    The resource group name (default: from terraform output)

.PARAMETER StorageAccountName
    The storage account name (default: from terraform output)

.PARAMETER ContainerName
    The container name (default: documents)

.EXAMPLE
    .\Upload-Documents.ps1

.NOTES
    Requires: PowerShell 7+, Azure CLI
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$ResourceGroupName,

    [Parameter()]
    [string]$StorageAccountName,

    [Parameter()]
    [string]$ContainerName = "documents"
)

$ErrorActionPreference = 'Stop'

Write-Host "🚀 Document Upload Script" -ForegroundColor Cyan
Write-Host "=" * 60

# Get Terraform outputs if parameters not provided
if (-not $ResourceGroupName -or -not $StorageAccountName) {
    Write-Host "📋 Getting deployment information from Terraform..." -ForegroundColor Yellow

    $terraformPath = Join-Path $PSScriptRoot "..\..\terraform\environments\poc"
    Push-Location $terraformPath

    try {
        $outputs = terraform output -json | ConvertFrom-Json

        if (-not $ResourceGroupName) {
            $ResourceGroupName = $outputs.resource_group_name.value
        }

        if (-not $StorageAccountName) {
            $StorageAccountName = $outputs.storage_account_name.value
        }

        Write-Host "  ✓ Resource Group: $ResourceGroupName" -ForegroundColor Green
        Write-Host "  ✓ Storage Account: $StorageAccountName" -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
}

# Find all markdown files in docs directory
$docsPath = Join-Path $PSScriptRoot "..\..\docs"
Write-Host "`n📁 Scanning for documents..." -ForegroundColor Yellow

$docFiles = Get-ChildItem -Path $docsPath -Filter "*.md" -Recurse | Where-Object {
    $_.Name -ne "DOCUMENT_MANIFEST.md"
}

Write-Host "  Found $($docFiles.Count) documents to upload" -ForegroundColor Green

if ($docFiles.Count -eq 0) {
    Write-Host "  ⚠️  No documents found to upload!" -ForegroundColor Yellow
    exit 0
}

# Get storage account key
Write-Host "`n🔑 Getting storage account key..." -ForegroundColor Yellow
$storageKey = az storage account keys list `
    --resource-group $ResourceGroupName `
    --account-name $StorageAccountName `
    --query "[0].value" `
    --output tsv

if ($LASTEXITCODE -ne 0) {
    throw "Failed to get storage account key"
}

Write-Host "  ✓ Storage key retrieved" -ForegroundColor Green

# Upload each document
Write-Host "`n📤 Uploading documents..." -ForegroundColor Yellow

$uploadedCount = 0
$failedCount = 0

foreach ($doc in $docFiles) {
    # Create blob name preserving directory structure
    $relativePath = $doc.FullName.Substring($docsPath.Length + 1)
    $blobName = $relativePath.Replace('\', '/')

    Write-Host "  Uploading: $blobName" -ForegroundColor Gray

    try {
        az storage blob upload `
            --account-name $StorageAccountName `
            --account-key $storageKey `
            --container-name $ContainerName `
            --name $blobName `
            --file $doc.FullName `
            --overwrite `
            --output none

        if ($LASTEXITCODE -eq 0) {
            $uploadedCount++
            Write-Host "    ✓ Uploaded" -ForegroundColor Green
        } else {
            $failedCount++
            Write-Host "    ✗ Failed" -ForegroundColor Red
        }
    }
    catch {
        $failedCount++
        Write-Host "    ✗ Error: $_" -ForegroundColor Red
    }
}

# Summary
Write-Host "`n" + ("=" * 60)
Write-Host "📊 Upload Summary:" -ForegroundColor Cyan
Write-Host "  ✓ Uploaded: $uploadedCount" -ForegroundColor Green
Write-Host "  ✗ Failed: $failedCount" -ForegroundColor $(if ($failedCount -gt 0) { "Red" } else { "Green" })
Write-Host "  📍 Container: $ContainerName" -ForegroundColor Gray
Write-Host "  📍 Storage: $StorageAccountName" -ForegroundColor Gray

if ($uploadedCount -gt 0) {
    Write-Host "`n✅ Documents uploaded successfully!" -ForegroundColor Green
    Write-Host "Next step: Run the indexing script to create embeddings and index documents." -ForegroundColor Yellow
}

if ($failedCount -gt 0) {
    Write-Host "`n⚠️  Some documents failed to upload. Check errors above." -ForegroundColor Yellow
    exit 1
}
