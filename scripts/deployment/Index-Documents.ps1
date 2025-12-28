<#
.SYNOPSIS
    Indexes documents in Azure AI Search with OpenAI embeddings

.DESCRIPTION
    Reads markdown documents, extracts metadata, generates embeddings using
    Azure OpenAI, and indexes them in Azure AI Search.

.PARAMETER SearchServiceName
    The search service name (default: from terraform output)

.PARAMETER IndexName
    The index name (default: docs-index)

.PARAMETER MaxDocuments
    Maximum number of documents to index (for testing)

.EXAMPLE
    .\Index-Documents.ps1

.EXAMPLE
    .\Index-Documents.ps1 -MaxDocuments 5

.NOTES
    Requires: PowerShell 7+, Azure CLI
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$SearchServiceName,

    [Parameter()]
    [string]$OpenAIServiceName,

    [Parameter()]
    [string]$ResourceGroupName,

    [Parameter()]
    [string]$IndexName = "docs-index",

    [Parameter()]
    [int]$MaxDocuments = 0
)

$ErrorActionPreference = 'Stop'

Write-Host "📚 Document Indexing Script" -ForegroundColor Cyan
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
            # Extract service name from endpoint
            $OpenAIServiceName = ($openaiEndpoint -replace 'https://', '' -replace '\.openai\.azure\.com/', '')
        }

        if (-not $ResourceGroupName) {
            $ResourceGroupName = $outputs.resource_group_name.value
        }

        Write-Host "  ✓ Search Service: $SearchServiceName" -ForegroundColor Green
        Write-Host "  ✓ OpenAI Service: $OpenAIServiceName" -ForegroundColor Green
        Write-Host "  ✓ Resource Group: $ResourceGroupName" -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
}

# Get keys
Write-Host "`n🔑 Getting API keys..." -ForegroundColor Yellow

$searchKey = az search admin-key show `
    --resource-group $ResourceGroupName `
    --service-name $SearchServiceName `
    --query "primaryKey" `
    --output tsv

$openaiKey = az cognitiveservices account keys list `
    --resource-group $ResourceGroupName `
    --name $OpenAIServiceName `
    --query "key1" `
    --output tsv

if ($LASTEXITCODE -ne 0) {
    throw "Failed to get API keys"
}

Write-Host "  ✓ Keys retrieved" -ForegroundColor Green

# Setup API endpoints
$searchEndpoint = "https://$SearchServiceName.search.windows.net"
$openaiEndpoint = "https://$OpenAIServiceName.openai.azure.com"

# Function to parse YAML frontmatter
function Parse-YamlFrontmatter {
    param([string]$Content)

    $metadata = @{}

    if ($Content -match '(?s)^---\s*\n(.*?)\n---\s*\n(.*)$') {
        $yamlContent = $Matches[1]
        $markdownContent = $Matches[2]

        $lines = $yamlContent -split "`n"
        $currentKey = $null
        $currentArray = @()

        for ($i = 0; $i -lt $lines.Length; $i++) {
            $line = $lines[$i]

            # Check for key-value pair
            if ($line -match '^(\w+):\s*(.*)$') {
                # Save previous array if we were building one
                if ($currentKey -and $currentArray.Count -gt 0) {
                    $metadata[$currentKey] = $currentArray
                    $currentArray = @()
                }

                $key = $Matches[1]
                $value = $Matches[2].Trim()

                # Handle inline arrays [item1, item2]
                if ($value -match '^\[(.*)\]$') {
                    $arrayContent = $Matches[1]
                    # Force result to be an array even with single element
                    $metadata[$key] = @($arrayContent -split ',\s*' | ForEach-Object { $_.Trim().Trim('"').Trim("'") })
                    $currentKey = $null
                }
                # Handle empty key (array will follow on next lines)
                elseif ($value -eq '' -or $value -eq $null) {
                    $currentKey = $key
                }
                # Handle simple string value
                else {
                    $metadata[$key] = $value.Trim('"').Trim("'")
                    $currentKey = $null
                }
            }
            # Check for array item (starts with -)
            elseif ($currentKey -and $line -match '^\s*-\s*"?([^"]+)"?\s*$') {
                $currentArray += $Matches[1].Trim()
            }
        }

        # Save final array if exists
        if ($currentKey -and $currentArray.Count -gt 0) {
            $metadata[$currentKey] = $currentArray
        }

        return @{
            Metadata = $metadata
            Content = $markdownContent.Trim()
        }
    }

    return @{
        Metadata = @{}
        Content = $Content
    }
}

# Function to ensure value is always an array
function Ensure-Array {
    param($Value)
    if ($null -eq $Value) {
        $result = @()
        return , $result  # Comma operator prevents unwrapping
    }
    if ($Value -is [array]) {
        return , $Value  # Comma operator prevents unwrapping
    }
    # Single value - wrap in array
    $result = @($Value)
    return , $result  # Comma operator prevents unwrapping
}

# Function to generate embedding with retry logic
function Get-Embedding {
    param([string]$Text)

    $body = @{
        input = $Text
    } | ConvertTo-Json

    $maxRetries = 3
    $retryDelay = 60  # Azure OpenAI requires 60 second wait for rate limits

    for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
        try {
            $response = Invoke-RestMethod `
                -Method Post `
                -Uri "$openaiEndpoint/openai/deployments/text-embedding-ada-002/embeddings?api-version=2023-05-15" `
                -Headers @{
                    "Content-Type" = "application/json"
                    "api-key" = $openaiKey
                } `
                -Body $body

            return $response.data[0].embedding
        }
        catch {
            if ($attempt -lt $maxRetries) {
                Write-Host "    ⚠️  Rate limit hit, waiting $retryDelay seconds (attempt $attempt/$maxRetries)..." -ForegroundColor Yellow
                Start-Sleep -Seconds $retryDelay
                $retryDelay = $retryDelay * 2  # Exponential backoff
            }
            else {
                Write-Host "    ⚠️  Error generating embedding after $maxRetries attempts: $_" -ForegroundColor Yellow
                return $null
            }
        }
    }

    return $null
}

# Find all markdown files
$docsPath = Join-Path $PSScriptRoot "..\..\docs"
Write-Host "`n📁 Scanning for documents..." -ForegroundColor Yellow

$docFiles = Get-ChildItem -Path $docsPath -Filter "*.md" -Recurse | Where-Object {
    $_.Name -ne "DOCUMENT_MANIFEST.md"
}

if ($MaxDocuments -gt 0 -and $docFiles.Count -gt $MaxDocuments) {
    Write-Host "  Limiting to $MaxDocuments documents (for testing)" -ForegroundColor Yellow
    $docFiles = $docFiles | Select-Object -First $MaxDocuments
}

Write-Host "  Found $($docFiles.Count) documents to index" -ForegroundColor Green

if ($docFiles.Count -eq 0) {
    Write-Host "  ⚠️  No documents found!" -ForegroundColor Yellow
    exit 0
}

# Index documents
Write-Host "`n🔄 Indexing documents..." -ForegroundColor Yellow

$indexedCount = 0
$failedCount = 0
$documents = @()

foreach ($doc in $docFiles) {
    $relativePath = $doc.FullName.Substring($docsPath.Length + 1)
    Write-Host "  Processing: $relativePath" -ForegroundColor Gray

    try {
        # Read and parse document
        $content = Get-Content $doc.FullName -Raw
        $parsed = Parse-YamlFrontmatter -Content $content

        # Extract title from first heading or filename
        $title = $doc.BaseName
        if ($parsed.Content -match '^#\s+(.+)$') {
            $title = $Matches[1]
        }

        # Generate embedding
        Write-Host "    Generating embedding..." -ForegroundColor Gray
        $embedding = Get-Embedding -Text $parsed.Content.Substring(0, [Math]::Min(8000, $parsed.Content.Length))

        if ($null -eq $embedding) {
            Write-Host "    ✗ Skipping (embedding failed)" -ForegroundColor Yellow
            $failedCount++
            continue
        }

        # Small delay to avoid rate limits
        Start-Sleep -Milliseconds 500

        # Ensure array fields are properly formatted
        $topicsArray = Ensure-Array $parsed.Metadata['topics']
        $technologiesArray = Ensure-Array $parsed.Metadata['technologies']
        $searchKeywordsArray = Ensure-Array $parsed.Metadata['search_keywords']

        # Create search document with default values for missing fields
        $searchDoc = [PSCustomObject]@{
            id = [System.Guid]::NewGuid().ToString()
            document_id = $parsed.Metadata['document_id'] ?? "doc-" + [System.Guid]::NewGuid().ToString().Substring(0,8)
            title = $title
            content = $parsed.Content
            document_type = $parsed.Metadata['document_type'] ?? "General"
            skill_level = $parsed.Metadata['skill_level'] ?? "intermediate"
            topics = $topicsArray
            technologies = $technologiesArray
            search_keywords = $searchKeywordsArray
            file_path = $relativePath
            estimated_time = [int]($parsed.Metadata['estimated_time'] ?? 0)
            content_vector = $embedding
        }

        # Parse last_reviewed date if present
        if ($parsed.Metadata['last_reviewed']) {
            try {
                $date = [DateTime]::Parse($parsed.Metadata['last_reviewed'])
                $searchDoc['last_reviewed'] = $date.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            }
            catch {
                # Skip if date parsing fails
            }
        }

        $documents += $searchDoc
        $indexedCount++
        Write-Host "    ✓ Processed" -ForegroundColor Green

        # Upload in batches of 10
        if ($documents.Count -ge 10) {
            Write-Host "`n  📤 Uploading batch to search index..." -ForegroundColor Yellow

            $uploadBody = @{
                value = $documents
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

                Write-Host "    ✓ Batch uploaded ($($documents.Count) documents)" -ForegroundColor Green
                $documents = @()
            }
            catch {
                Write-Host "    ✗ Batch upload failed: $_" -ForegroundColor Red
                $failedCount += $documents.Count
                $documents = @()
            }
        }
    }
    catch {
        Write-Host "    ✗ Error: $_" -ForegroundColor Red
        $failedCount++
    }
}

# Upload remaining documents
if ($documents.Count -gt 0) {
    Write-Host "`n  📤 Uploading final batch to search index..." -ForegroundColor Yellow

    $uploadBody = @{
        value = $documents
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

        Write-Host "    ✓ Final batch uploaded ($($documents.Count) documents)" -ForegroundColor Green
    }
    catch {
        Write-Host "    ✗ Final batch upload failed: $_" -ForegroundColor Red
        $failedCount += $documents.Count
    }
}

# Summary
Write-Host "`n" + ("=" * 60)
Write-Host "📊 Indexing Summary:" -ForegroundColor Cyan
Write-Host "  ✓ Indexed: $indexedCount" -ForegroundColor Green
Write-Host "  ✗ Failed: $failedCount" -ForegroundColor $(if ($failedCount -gt 0) { "Red" } else { "Green" })
Write-Host "  📍 Index: $IndexName" -ForegroundColor Gray
Write-Host "  📍 Search Service: $SearchServiceName" -ForegroundColor Gray

if ($indexedCount -gt 0) {
    Write-Host "`n✅ Documents indexed successfully!" -ForegroundColor Green
    Write-Host "Next step: Use the search interface to test queries." -ForegroundColor Yellow
}

if ($failedCount -gt 0) {
    Write-Host "`n⚠️  Some documents failed to index. Check errors above." -ForegroundColor Yellow
    exit 1
}
