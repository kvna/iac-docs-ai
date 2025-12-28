<#
.SYNOPSIS
    Quick test script to add sample documents and test search

.DESCRIPTION
    Adds a few sample documents to the search index without embeddings
    to demonstrate keyword search functionality.

.NOTES
    Requires: PowerShell 7+, Azure CLI
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$SearchServiceName,

    [Parameter()]
    [string]$ResourceGroupName,

    [Parameter()]
    [string]$IndexName = "docs-index"
)

$ErrorActionPreference = 'Stop'

Write-Host "🧪 Quick Search Test" -ForegroundColor Cyan
Write-Host "=" * 60

# Get Terraform outputs if parameters not provided
if (-not $SearchServiceName -or -not $ResourceGroupName) {
    Write-Host "📋 Getting deployment information from Terraform..." -ForegroundColor Yellow

    $terraformPath = Join-Path $PSScriptRoot "..\..\terraform\environments\poc"
    Push-Location $terraformPath

    try {
        $outputs = terraform output -json | ConvertFrom-Json

        if (-not $SearchServiceName) {
            $SearchServiceName = $outputs.search_service_name.value
        }

        if (-not $ResourceGroupName) {
            $ResourceGroupName = $outputs.resource_group_name.value
        }
    }
    finally {
        Pop-Location
    }
}

Write-Host "  ✓ Search Service: $SearchServiceName" -ForegroundColor Green

# Get search admin key
Write-Host "`n🔑 Getting search admin key..." -ForegroundColor Yellow
$searchKey = az search admin-key show `
    --resource-group $ResourceGroupName `
    --service-name $SearchServiceName `
    --query "primaryKey" `
    --output tsv

if ($LASTEXITCODE -ne 0) {
    throw "Failed to get search admin key"
}

Write-Host "  ✓ Key retrieved" -ForegroundColor Green

$searchEndpoint = "https://$SearchServiceName.search.windows.net"

# Add sample documents without embeddings (for keyword search testing)
Write-Host "`n📝 Adding sample test documents..." -ForegroundColor Yellow

$sampleDocs = @(
    @{
        id = "test-001"
        document_id = "concept-001"
        title = "Infrastructure as Code Overview"
        content = "Infrastructure as Code (IaC) is the practice of managing and provisioning infrastructure through code instead of manual processes. With IaC, you can define your infrastructure in version-controlled files."
        document_type = "Concept"
        skill_level = "day1"
        topics = @("IaC", "DevOps", "Automation")
        technologies = @("Terraform", "Azure")
        search_keywords = @("infrastructure", "code", "automation", "terraform")
        file_path = "test/concept-iac.md"
        estimated_time = 10
    },
    @{
        id = "test-002"
        document_id = "howto-001"
        title = "How to Deploy with Terraform"
        content = "This guide shows you how to deploy infrastructure using Terraform. First, initialize your workspace with terraform init, then create a plan with terraform plan, and finally apply it with terraform apply."
        document_type = "How-To"
        skill_level = "day1"
        topics = @("Terraform", "Deployment")
        technologies = @("Terraform", "Azure", "CLI")
        search_keywords = @("terraform", "deploy", "init", "plan", "apply")
        file_path = "test/howto-terraform-deploy.md"
        estimated_time = 15
    }
)

$uploadBody = @{
    value = $sampleDocs
} | ConvertTo-Json -Depth 10

try {
    $result = Invoke-RestMethod `
        -Method Post `
        -Uri "$searchEndpoint/indexes/$IndexName/docs/index?api-version=2023-11-01" `
        -Headers @{
            "Content-Type" = "application/json"
            "api-key" = $searchKey
        } `
        -Body $uploadBody

    Write-Host "  ✓ Sample documents added" -ForegroundColor Green
}
catch {
    Write-Host "  ✗ Failed to add documents: $_" -ForegroundColor Red
    throw
}

# Test keyword search
Write-Host "`n🔎 Testing keyword search..." -ForegroundColor Yellow

$searchBody = @{
    search = "terraform deploy"
    top = 5
    select = "document_id,title,content,document_type,skill_level,topics"
} | ConvertTo-Json

try {
    $searchResult = Invoke-RestMethod `
        -Method Post `
        -Uri "$searchEndpoint/indexes/$IndexName/docs/search?api-version=2023-11-01" `
        -Headers @{
            "Content-Type" = "application/json"
            "api-key" = $searchKey
        } `
        -Body $searchBody

    Write-Host "  ✓ Search completed" -ForegroundColor Green
    Write-Host "  Found: $($searchResult.value.Count) results" -ForegroundColor Green

    if ($searchResult.value.Count -gt 0) {
        Write-Host "`n📄 Results:" -ForegroundColor Cyan
        foreach ($doc in $searchResult.value) {
            Write-Host "  - $($doc.title) (Score: $($doc.'@search.score'))" -ForegroundColor White
        }
    }
}
catch {
    Write-Host "  ✗ Search failed: $_" -ForegroundColor Red
    throw
}

Write-Host "`n" + ("=" * 60)
Write-Host "✅ Search system is working!" -ForegroundColor Green
Write-Host "`nYou can now use:" -ForegroundColor Yellow
Write-Host "  pwsh scripts/deployment/Search-Documents.ps1 -Query 'your query' -SearchMode keyword" -ForegroundColor Gray
