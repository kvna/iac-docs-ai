<#
.SYNOPSIS
    Ask questions and get AI-powered answers from your documentation

.DESCRIPTION
    Uses RAG (Retrieval Augmented Generation) to search your docs and generate
    answers using GPT-4o-mini. Searches for relevant documents, reads their content,
    and uses AI to provide accurate answers based on your documentation.

.PARAMETER Question
    Your question about the documentation

.PARAMETER SearchServiceName
    The search service name (default: from terraform output)

.PARAMETER OpenAIServiceName
    The OpenAI service name (default: from terraform output)

.PARAMETER IndexName
    The index name (default: docs-index)

.PARAMETER TopDocs
    Number of documents to retrieve for context (default: 3)

.PARAMETER SearchMode
    Search mode: vector, keyword, or hybrid (default: hybrid)

.EXAMPLE
    .\Ask-Documentation.ps1 -Question "How do I set up Terraform?"

.EXAMPLE
    .\Ask-Documentation.ps1 -Question "What are the naming conventions for Azure resources?"

.NOTES
    Requires: PowerShell 7+, Azure CLI
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$Question,

    [Parameter()]
    [string]$SearchServiceName,

    [Parameter()]
    [string]$OpenAIServiceName,

    [Parameter()]
    [string]$ResourceGroupName,

    [Parameter()]
    [string]$IndexName = "docs-index",

    [Parameter()]
    [int]$TopDocs = 3,

    [Parameter()]
    [ValidateSet("vector", "keyword", "hybrid")]
    [string]$SearchMode = "hybrid"
)

$ErrorActionPreference = 'Stop'

Write-Host "🤖 AI Documentation Assistant" -ForegroundColor Cyan
Write-Host "=" * 60
Write-Host "Question: " -ForegroundColor Yellow -NoNewline
Write-Host "`"$Question`"" -ForegroundColor White
Write-Host ""

# Get Terraform outputs if parameters not provided
if (-not $SearchServiceName -or -not $OpenAIServiceName -or -not $ResourceGroupName) {
    Write-Host "📋 Getting deployment information..." -ForegroundColor Gray

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

# Get API keys
Write-Host "🔑 Authenticating..." -ForegroundColor Gray

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

# Setup endpoints
$searchEndpoint = "https://$SearchServiceName.search.windows.net"
$openaiEndpoint = "https://$OpenAIServiceName.openai.azure.com"

# Generate query embedding for vector/hybrid search
$queryVector = $null
if ($SearchMode -in @("vector", "hybrid")) {
    Write-Host "🧮 Generating query embedding..." -ForegroundColor Gray

    try {
        $embeddingBody = @{
            input = $Question
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
    }
    catch {
        Write-Host "  ⚠️  Failed to generate embedding, using keyword search" -ForegroundColor Yellow
        $SearchMode = "keyword"
    }
}

# Search for relevant documents
Write-Host "🔍 Searching documentation..." -ForegroundColor Gray

$searchBody = @{
    top = $TopDocs
    select = "document_id,title,content,document_type,skill_level,file_path"
    queryType = "simple"
}

switch ($SearchMode) {
    "vector" {
        $searchBody.vectorQueries = @(
            @{
                kind = "vector"
                vector = $queryVector
                fields = "content_vector"
                k = $TopDocs
            }
        )
    }
    "keyword" {
        $searchBody.search = $Question
    }
    "hybrid" {
        $searchBody.search = $Question
        $searchBody.vectorQueries = @(
            @{
                kind = "vector"
                vector = $queryVector
                fields = "content_vector"
                k = $TopDocs
            }
        )
    }
}

try {
    $searchUri = "$searchEndpoint/indexes/$IndexName/docs/search?api-version=2023-11-01"
    $searchBodyJson = $searchBody | ConvertTo-Json -Depth 10

    $searchResponse = Invoke-RestMethod `
        -Method Post `
        -Uri $searchUri `
        -Headers @{
            "Content-Type" = "application/json"
            "api-key" = $searchKey
        } `
        -Body $searchBodyJson

    $results = $searchResponse.value

    if ($results.Count -eq 0) {
        Write-Host "`n❌ No relevant documentation found for your question." -ForegroundColor Red
        Write-Host "Try rephrasing your question or check if documents are indexed." -ForegroundColor Yellow
        exit 0
    }

    Write-Host "  ✓ Found $($results.Count) relevant document(s)" -ForegroundColor Green
}
catch {
    Write-Host "`n❌ Search failed: $_" -ForegroundColor Red
    throw
}

# Build context from retrieved documents
Write-Host "📚 Reading relevant documentation..." -ForegroundColor Gray

$context = ""
$sources = @()

foreach ($doc in $results) {
    $context += "Document: $($doc.title)`n"
    $context += "Type: $($doc.document_type) | Level: $($doc.skill_level)`n"
    $context += "Content:`n$($doc.content)`n"
    $context += "`n---`n`n"

    $sources += @{
        title = $doc.title
        type = $doc.document_type
        path = $doc.file_path
    }
}

# Generate answer using GPT-4o-mini
Write-Host "🤔 Generating answer..." -ForegroundColor Gray

$systemPrompt = @"
You are a helpful AI assistant that answers questions based ONLY on the provided documentation.

IMPORTANT RULES:
- Only use information from the documents provided in the context
- If the answer is not in the provided documents, say "I don't have information about that in the available documentation"
- Be concise but complete
- Use bullet points or numbered lists for multi-step answers
- Include relevant examples from the docs when available
- Use technical terms correctly as they appear in the documentation

The user's question is about infrastructure as code, Azure, and Terraform documentation.
"@

$userPrompt = @"
QUESTION: $Question

CONTEXT FROM DOCUMENTATION:
$context

Please answer the question based on the documentation provided above.
"@

$chatBody = @{
    messages = @(
        @{
            role = "system"
            content = $systemPrompt
        },
        @{
            role = "user"
            content = $userPrompt
        }
    )
    max_tokens = 1000
    temperature = 0.3
    top_p = 0.9
} | ConvertTo-Json -Depth 10

try {
    $chatResponse = Invoke-RestMethod `
        -Method Post `
        -Uri "$openaiEndpoint/openai/deployments/gpt-4o-mini/chat/completions?api-version=2024-02-15-preview" `
        -Headers @{
            "Content-Type" = "application/json"
            "api-key" = $openaiKey
        } `
        -Body $chatBody

    $answer = $chatResponse.choices[0].message.content

    # Display answer
    Write-Host "`n" + ("=" * 60)
    Write-Host "💡 Answer:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host $answer -ForegroundColor White
    Write-Host ""

    # Display sources
    Write-Host ("=" * 60)
    Write-Host "📖 Sources:" -ForegroundColor Cyan
    foreach ($source in $sources) {
        Write-Host "  • " -ForegroundColor Gray -NoNewline
        Write-Host $source.title -ForegroundColor Yellow -NoNewline
        Write-Host " ($($source.type))" -ForegroundColor Gray
        Write-Host "    📁 $($source.path)" -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "=" * 60
    Write-Host "✅ Done! Ask another question or read the full docs for more details." -ForegroundColor Green
}
catch {
    Write-Host "`n❌ Failed to generate answer: $_" -ForegroundColor Red

    if ($_.Exception.Response) {
        $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        $errorDetails = $reader.ReadToEnd()
        Write-Host "Error details: $errorDetails" -ForegroundColor Red
    }

    throw
}
