<#
.SYNOPSIS
    Creates Azure AI Search index for documentation

.DESCRIPTION
    Creates an Azure AI Search index with schema optimized for documentation search,
    including vector embeddings support and semantic search configuration.

.PARAMETER SearchServiceName
    The search service name (default: from terraform output)

.PARAMETER IndexName
    The index name (default: docs-index)

.EXAMPLE
    .\Create-SearchIndex.ps1

.NOTES
    Requires: PowerShell 7+, Azure CLI
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$SearchServiceName,

    [Parameter()]
    [string]$IndexName = "docs-index",

    [Parameter()]
    [string]$ResourceGroupName
)

$ErrorActionPreference = 'Stop'

Write-Host "🔍 Azure AI Search Index Creation" -ForegroundColor Cyan
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

        Write-Host "  ✓ Search Service: $SearchServiceName" -ForegroundColor Green
        Write-Host "  ✓ Resource Group: $ResourceGroupName" -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
}

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

Write-Host "  ✓ Search key retrieved" -ForegroundColor Green

# Define index schema
Write-Host "`n📐 Creating index schema..." -ForegroundColor Yellow

$indexSchema = @{
    name = $IndexName
    fields = @(
        @{
            name = "id"
            type = "Edm.String"
            key = $true
            searchable = $false
            filterable = $false
            sortable = $false
        },
        @{
            name = "document_id"
            type = "Edm.String"
            searchable = $true
            filterable = $true
            sortable = $true
            facetable = $true
        },
        @{
            name = "title"
            type = "Edm.String"
            searchable = $true
            filterable = $false
            sortable = $true
        },
        @{
            name = "content"
            type = "Edm.String"
            searchable = $true
            filterable = $false
            sortable = $false
        },
        @{
            name = "document_type"
            type = "Edm.String"
            searchable = $true
            filterable = $true
            facetable = $true
        },
        @{
            name = "skill_level"
            type = "Edm.String"
            searchable = $false
            filterable = $true
            facetable = $true
        },
        @{
            name = "topics"
            type = "Collection(Edm.String)"
            searchable = $true
            filterable = $true
            facetable = $true
        },
        @{
            name = "technologies"
            type = "Collection(Edm.String)"
            searchable = $true
            filterable = $true
            facetable = $true
        },
        @{
            name = "search_keywords"
            type = "Collection(Edm.String)"
            searchable = $true
            filterable = $false
        },
        @{
            name = "file_path"
            type = "Edm.String"
            searchable = $false
            filterable = $true
        },
        @{
            name = "last_reviewed"
            type = "Edm.DateTimeOffset"
            searchable = $false
            filterable = $true
            sortable = $true
        },
        @{
            name = "estimated_time"
            type = "Edm.Int32"
            searchable = $false
            filterable = $true
            sortable = $true
        },
        @{
            name = "content_vector"
            type = "Collection(Edm.Single)"
            searchable = $true
            filterable = $false
            sortable = $false
            dimensions = 1536
            vectorSearchProfile = "vector-profile"
        }
    )
    vectorSearch = @{
        profiles = @(
            @{
                name = "vector-profile"
                algorithm = "vector-algorithm"
            }
        )
        algorithms = @(
            @{
                name = "vector-algorithm"
                kind = "hnsw"
                hnswParameters = @{
                    metric = "cosine"
                    m = 4
                    efConstruction = 400
                    efSearch = 500
                }
            }
        )
    }
}

# Save schema to temp file
$schemaFile = [System.IO.Path]::GetTempFileName()
$indexSchema | ConvertTo-Json -Depth 10 | Set-Content -Path $schemaFile

Write-Host "  ✓ Schema created" -ForegroundColor Green

# Create the index
Write-Host "`n🏗️  Creating search index..." -ForegroundColor Yellow

$searchEndpoint = "https://$SearchServiceName.search.windows.net"

try {
    $response = Invoke-RestMethod `
        -Method Put `
        -Uri "$searchEndpoint/indexes/$($IndexName)?api-version=2023-11-01" `
        -Headers @{
            "Content-Type" = "application/json"
            "api-key" = $searchKey
        } `
        -Body (Get-Content $schemaFile -Raw)

    Write-Host "  ✓ Index created successfully!" -ForegroundColor Green
    Write-Host "`n📊 Index Details:" -ForegroundColor Cyan
    Write-Host "  Name: $IndexName" -ForegroundColor Gray
    Write-Host "  Fields: $($response.fields.Count)" -ForegroundColor Gray
    Write-Host "  Vector Search: Enabled (1536 dimensions)" -ForegroundColor Gray
    Write-Host "  Hybrid Search: Enabled (vector + keyword)" -ForegroundColor Gray
}
catch {
    if ($_.Exception.Response.StatusCode -eq 'Conflict') {
        Write-Host "  ⚠️  Index already exists. Updating..." -ForegroundColor Yellow

        # Try to update existing index
        try {
            $response = Invoke-RestMethod `
                -Method Put `
                -Uri "$searchEndpoint/indexes/$($IndexName)?api-version=2023-11-01&allowIndexDowntime=true" `
                -Headers @{
                    "Content-Type" = "application/json"
                    "api-key" = $searchKey
                } `
                -Body (Get-Content $schemaFile -Raw)

            Write-Host "  ✓ Index updated successfully!" -ForegroundColor Green
        }
        catch {
            Write-Host "  ✗ Failed to update index: $_" -ForegroundColor Red
            throw
        }
    }
    else {
        Write-Host "  ✗ Failed to create index: $_" -ForegroundColor Red
        throw
    }
}
finally {
    # Clean up temp file
    if (Test-Path $schemaFile) {
        Remove-Item $schemaFile -Force
    }
}

Write-Host "`n✅ Search index is ready!" -ForegroundColor Green
Write-Host "Next step: Run the document indexing script to populate the index." -ForegroundColor Yellow
