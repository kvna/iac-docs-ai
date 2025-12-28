<#
.SYNOPSIS
    Search indexed documents using Azure AI Search

.DESCRIPTION
    Performs semantic and vector search on indexed documentation using
    Azure AI Search with OpenAI embeddings.

.PARAMETER Query
    The search query

.PARAMETER SearchServiceName
    The search service name (default: from terraform output)

.PARAMETER IndexName
    The index name (default: docs-index)

.PARAMETER Top
    Number of results to return (default: 5)

.PARAMETER SearchMode
    Search mode: vector, keyword, hybrid, or semantic (default: semantic)

.EXAMPLE
    .\Search-Documents.ps1 -Query "How do I deploy terraform?"

.EXAMPLE
    .\Search-Documents.ps1 -Query "Azure OpenAI setup" -SearchMode hybrid -Top 10

.NOTES
    Requires: PowerShell 7+, Azure CLI
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$Query,

    [Parameter()]
    [string]$SearchServiceName,

    [Parameter()]
    [string]$OpenAIServiceName,

    [Parameter()]
    [string]$ResourceGroupName,

    [Parameter()]
    [string]$IndexName = "docs-index",

    [Parameter()]
    [int]$Top = 5,

    [Parameter()]
    [ValidateSet("vector", "keyword", "hybrid")]
    [string]$SearchMode = "hybrid"
)

$ErrorActionPreference = 'Stop'

Write-Host "🔍 Azure AI Search - Document Search" -ForegroundColor Cyan
Write-Host "=" * 60

# Get Terraform outputs if parameters not provided
if (-not $SearchServiceName -or -not $OpenAIServiceName -or -not $ResourceGroupName) {
    Write-Host "📋 Getting deployment information from Terraform..." -ForegroundColor Yellow

    $terraformPath = Join-Path $PSScriptRoot "..\..\terraform\environments\poc"
    Push-Location $terraformPath

    try {
        $outputs = terraform output -json | ConvertFrom-Json

        if (-not $SearchServiceName) {
            $SearchServiceName = $outputs.search_service_name.value
        }

        if (-not $OpenAIServiceName) {
            $openaiEndpoint = $outputs.openai_endpoint.value
            $OpenAIServiceName = ($openaiEndpoint -replace 'https://', '' -replace '\.openai\.azure\.com/', '')
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
Write-Host "  ✓ OpenAI Service: $OpenAIServiceName" -ForegroundColor Green

# Get API keys
Write-Host "`n🔑 Getting API keys..." -ForegroundColor Yellow

$searchKey = az search admin-key show `
    --resource-group $ResourceGroupName `
    --service-name $SearchServiceName `
    --query "primaryKey" `
    --output tsv

if ($LASTEXITCODE -ne 0) {
    throw "Failed to get search key"
}

Write-Host "  ✓ Keys retrieved" -ForegroundColor Green

# Setup endpoints
$searchEndpoint = "https://$SearchServiceName.search.windows.net"
$openaiEndpoint = "https://$OpenAIServiceName.openai.azure.com"

# Generate query embedding for vector search
$queryVector = $null
if ($SearchMode -in @("vector", "hybrid")) {
    Write-Host "`n🧮 Generating query embedding..." -ForegroundColor Yellow

    $openaiKey = az cognitiveservices account keys list `
        --resource-group $ResourceGroupName `
        --name $OpenAIServiceName `
        --query "key1" `
        --output tsv

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to get OpenAI key"
    }

    try {
        $embeddingBody = @{
            input = $Query
        } | ConvertTo-Json

        $embeddingResponse = Invoke-RestMethod `
            -Method Post `
            -Uri "$openaiEndpoint/openai/deployments/text-embedding-ada-002/embeddings?api-version=2023-05-15" `
            -Headers @{
                "Content-Type" = "application/json"
                "api-key" = $openaiKey
            } `
            -Body $embeddingBody

        $queryVector = $embeddingResponse.data[0].embedding
        Write-Host "  ✓ Query vector generated" -ForegroundColor Green
    }
    catch {
        Write-Host "  ⚠️  Failed to generate embedding, falling back to keyword search" -ForegroundColor Yellow
        $SearchMode = "keyword"
    }
}

# Build search request
Write-Host "`n🔎 Searching documents..." -ForegroundColor Yellow
Write-Host "  Query: `"$Query`"" -ForegroundColor Gray
Write-Host "  Mode: $SearchMode" -ForegroundColor Gray

$searchBody = @{
    top = $Top
    select = "document_id,title,content,document_type,skill_level,topics,technologies,file_path,estimated_time"
    queryType = "simple"
}

switch ($SearchMode) {
    "vector" {
        $searchBody.vectorQueries = @(
            @{
                kind = "vector"
                vector = $queryVector
                fields = "content_vector"
                k = $Top
            }
        )
    }
    "keyword" {
        $searchBody.search = $Query
    }
    "hybrid" {
        $searchBody.search = $Query
        $searchBody.vectorQueries = @(
            @{
                kind = "vector"
                vector = $queryVector
                fields = "content_vector"
                k = $Top
            }
        )
    }
}

# Perform search
try {
    $searchUri = "$searchEndpoint/indexes/$IndexName/docs/search?api-version=2023-11-01"
    $searchBodyJson = $searchBody | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod `
        -Method Post `
        -Uri $searchUri `
        -Headers @{
            "Content-Type" = "application/json"
            "api-key" = $searchKey
        } `
        -Body $searchBodyJson

    $results = $response.value

    if ($results.Count -eq 0) {
        Write-Host "`n  📭 No results found" -ForegroundColor Yellow
        exit 0
    }

    Write-Host "  ✓ Found $($results.Count) results" -ForegroundColor Green

    # Display results
    Write-Host "`n📄 Search Results:" -ForegroundColor Cyan
    Write-Host "=" * 60

    $resultNumber = 1
    foreach ($result in $results) {
        Write-Host "`n[$resultNumber] " -ForegroundColor Cyan -NoNewline
        Write-Host $result.title -ForegroundColor White

        # Score
        if ($result.'@search.score') {
            Write-Host "    Score: " -ForegroundColor Gray -NoNewline
            Write-Host $result.'@search.score' -ForegroundColor Yellow
        }

        # Metadata
        Write-Host "    Type: " -ForegroundColor Gray -NoNewline
        Write-Host "$($result.document_type)" -ForegroundColor White -NoNewline
        Write-Host " | " -ForegroundColor Gray -NoNewline
        Write-Host "Level: " -ForegroundColor Gray -NoNewline
        Write-Host "$($result.skill_level)" -ForegroundColor White

        if ($result.topics -and $result.topics.Count -gt 0) {
            Write-Host "    Topics: " -ForegroundColor Gray -NoNewline
            Write-Host ($result.topics -join ", ") -ForegroundColor Magenta
        }

        if ($result.technologies -and $result.technologies.Count -gt 0) {
            Write-Host "    Tech: " -ForegroundColor Gray -NoNewline
            Write-Host ($result.technologies -join ", ") -ForegroundColor Blue
        }

        if ($result.estimated_time -gt 0) {
            Write-Host "    Time: " -ForegroundColor Gray -NoNewline
            Write-Host "$($result.estimated_time) min" -ForegroundColor White
        }

        # Content snippet
        $snippet = $result.content
        if ($snippet.Length -gt 200) {
            $snippet = $snippet.Substring(0, 200) + "..."
        }
        Write-Host "    `"$snippet`"" -ForegroundColor DarkGray

        # File path
        Write-Host "    📁 " -ForegroundColor Gray -NoNewline
        Write-Host $result.file_path -ForegroundColor DarkGray

        $resultNumber++
    }

    Write-Host "`n" + ("=" * 60)
    Write-Host "✅ Search completed successfully!" -ForegroundColor Green
}
catch {
    Write-Host "`n✗ Search failed: $_" -ForegroundColor Red

    if ($_.Exception.Response) {
        $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        $errorDetails = $reader.ReadToEnd()
        Write-Host "Error details: $errorDetails" -ForegroundColor Red
    }

    throw
}
