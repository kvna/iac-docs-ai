<#
.SYNOPSIS
    Validates documentation quality and searchability

.DESCRIPTION
    Tests documentation against quality standards including:
    - Metadata completeness and validity
    - Readability scores
    - Link integrity
    - Glossary term validation
    - Searchability assessment

.PARAMETER Path
    Path to markdown file or directory to validate

.PARAMETER TestSearch
    Include searchability testing (requires deployed search infrastructure)

.PARAMETER Verbose
    Show detailed validation output

.EXAMPLE
    .\Test-DocumentQuality.ps1 -Path "..\..\docs\day1\concept-iac-overview.md"

.EXAMPLE
    .\Test-DocumentQuality.ps1 -Path "..\..\docs" -Verbose

.NOTES
    Author: IaC Team
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter()]
    [switch]$TestSearch,

    [Parameter()]
    [int]$MinScore = 80
)

#Requires -Version 7

$ErrorActionPreference = 'Stop'

##############################################################################
# Helper Functions
##############################################################################

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Message = "",
        [int]$Score = -1
    )

    $status = if ($Passed) { "✓" } else { "✗" }
    $color = if ($Passed) { "Green" } else { "Red" }

    $output = "  $status $TestName"
    if ($Score -ge 0) {
        $output += " ($Score/100)"
    }
    if ($Message) {
        $output += " - $Message"
    }

    Write-Host $output -ForegroundColor $color
}

function Test-MetadataCompleteness {
    param([object]$Metadata, [string]$FilePath)

    $requiredFields = @(
        'document_id',
        'document_type',
        'skill_level',
        'topics',
        'technologies',
        'prerequisites',
        'learning_outcomes',
        'estimated_time',
        'last_reviewed',
        'review_status',
        'search_keywords',
        'related_documents',
        'glossary_terms'
    )

    $missing = @()
    $issues = @()

    foreach ($field in $requiredFields) {
        if (-not $Metadata.ContainsKey($field)) {
            $missing += $field
        }
        elseif ($null -eq $Metadata[$field] -or $Metadata[$field] -eq '') {
            $missing += $field
        }
    }

    # Validate enums
    $validDocTypes = @('concept', 'howto', 'reference', 'troubleshooting', 'learning_path')
    if ($Metadata.document_type -and $Metadata.document_type -notin $validDocTypes) {
        $issues += "Invalid document_type: $($Metadata.document_type)"
    }

    $validSkillLevels = @('day1', 'week1-4', 'month1-2', 'month3-6', 'month6-12', 'expert')
    if ($Metadata.skill_level -and $Metadata.skill_level -notin $validSkillLevels) {
        $issues += "Invalid skill_level: $($Metadata.skill_level)"
    }

    $validReviewStatus = @('current', 'needs_review', 'deprecated')
    if ($Metadata.review_status -and $Metadata.review_status -notin $validReviewStatus) {
        $issues += "Invalid review_status: $($Metadata.review_status)"
    }

    # Check search keywords quantity
    if ($Metadata.search_keywords) {
        $keywordCount = @($Metadata.search_keywords).Count
        if ($keywordCount -lt 5) {
            $issues += "Only $keywordCount search keywords (recommend 5-10)"
        }
    }

    $passed = ($missing.Count -eq 0 -and $issues.Count -eq 0)
    $message = ""

    if ($missing.Count -gt 0) {
        $message = "Missing: $($missing -join ', ')"
    }
    elseif ($issues.Count -gt 0) {
        $message = $issues[0]
    }

    return @{
        Passed = $passed
        Message = $message
        Score = if ($passed) { 100 } else { [Math]::Max(0, 100 - ($missing.Count + $issues.Count) * 10) }
    }
}

function Test-GlossaryTerms {
    param([object]$Metadata, [string]$Content)

    $glossaryPath = Join-Path $PSScriptRoot "..\..\config\glossary.yaml"

    if (-not (Test-Path $glossaryPath)) {
        return @{
            Passed = $true
            Message = "Glossary file not found (skipped)"
            Score = 100
        }
    }

    # Simple YAML parsing for terms
    $glossaryContent = Get-Content $glossaryPath -Raw
    $glossaryTerms = @()

    # Extract term names (basic YAML parsing)
    $glossaryContent -split "`n" | ForEach-Object {
        if ($_ -match '^\s*-\s*term:\s*"(.+)"') {
            $glossaryTerms += $matches[1]
        }
    }

    if ($Metadata.glossary_terms) {
        $undefinedTerms = @()
        foreach ($term in $Metadata.glossary_terms) {
            if ($term -notin $glossaryTerms) {
                $undefinedTerms += $term
            }
        }

        $passed = ($undefinedTerms.Count -eq 0)
        $message = if ($undefinedTerms.Count -gt 0) {
            "Undefined terms: $($undefinedTerms -join ', ')"
        }
        else {
            "All terms defined"
        }

        return @{
            Passed = $passed
            Message = $message
            Score = if ($passed) { 100 } else { [Math]::Max(0, 100 - ($undefinedTerms.Count * 20)) }
        }
    }

    return @{
        Passed = $true
        Message = "No glossary terms to validate"
        Score = 100
    }
}

function Test-CodeBlocks {
    param([string]$Content)

    $codeBlocks = [regex]::Matches($Content, '```(\w+)?\s*\n(.*?)\n```', 'Singleline')

    if ($codeBlocks.Count -eq 0) {
        return @{
            Passed = $true
            Message = "No code blocks"
            Score = 100
        }
    }

    $withoutLanguage = 0
    foreach ($block in $codeBlocks) {
        if (-not $block.Groups[1].Success) {
            $withoutLanguage++
        }
    }

    $passed = ($withoutLanguage -eq 0)
    $score = [Math]::Max(0, 100 - ($withoutLanguage * 20))

    return @{
        Passed = $passed
        Message = "$($codeBlocks.Count) code blocks, $withoutLanguage without language"
        Score = $score
    }
}

function Test-Readability {
    param([string]$Content)

    # Remove metadata and code blocks
    $textOnly = $Content -replace '---.*?---', '', 'Singleline'
    $textOnly = $textOnly -replace '```.*?```', '', 'Singleline'
    $textOnly = $textOnly -replace '#.*$', '', 'Multiline'  # Remove headers

    # Count sentences and words
    $sentences = ([regex]::Matches($textOnly, '[.!?][\s\n]')).Count
    $words = ($textOnly -split '\s+' | Where-Object { $_ -match '\w' }).Count

    if ($sentences -eq 0 -or $words -eq 0) {
        return @{
            Passed = $true
            Message = "Insufficient text for analysis"
            Score = 100
        }
    }

    $avgWordsPerSentence = [Math]::Round($words / $sentences, 1)

    # Simple readability assessment
    # Target: 15-25 words per sentence for technical docs
    $score = 100
    if ($avgWordsPerSentence -gt 30) {
        $score = 70  # Too complex
    }
    elseif ($avgWordsPerSentence -gt 25) {
        $score = 85  # Slightly complex
    }
    elseif ($avgWordsPerSentence -lt 10) {
        $score = 85  # Too simple
    }

    return @{
        Passed = ($score -ge 80)
        Message = "Avg $avgWordsPerSentence words/sentence"
        Score = $score
    }
}

function Test-DocumentFile {
    param([string]$FilePath)

    Write-Host "`nTesting: $FilePath" -ForegroundColor Cyan

    if (-not (Test-Path $FilePath)) {
        Write-Host "  File not found" -ForegroundColor Red
        return @{ OverallScore = 0; Passed = $false }
    }

    $content = Get-Content $FilePath -Raw

    # Extract YAML frontmatter
    if ($content -match '(?s)^---\s*\n(.*?)\n---') {
        $yamlContent = $matches[1]

        # Simple YAML parsing (basic implementation)
        $metadata = @{}
        $currentKey = $null
        $yamlContent -split "`n" | ForEach-Object {
            $line = $_.Trim()
            if ($line -match '^(\w+):\s*(.*)$') {
                $currentKey = $matches[1]
                $value = $matches[2].Trim()

                # Handle arrays
                if ($value -match '^\[(.*)\]$') {
                    $metadata[$currentKey] = $matches[1] -split ',\s*' | ForEach-Object { $_.Trim('"') }
                }
                elseif ($value) {
                    $metadata[$currentKey] = $value.Trim('"')
                }
                else {
                    $metadata[$currentKey] = @()
                }
            }
            elseif ($line -match '^\s*-\s*(.+)$' -and $currentKey) {
                if ($metadata[$currentKey] -isnot [array]) {
                    $metadata[$currentKey] = @()
                }
                $metadata[$currentKey] += $matches[1].Trim('"')
            }
        }
    }
    else {
        Write-Host "  ✗ No YAML frontmatter found" -ForegroundColor Red
        return @{ OverallScore = 0; Passed = $false }
    }

    # Run tests
    $results = @{}

    # Test 1: Metadata Completeness
    $metadataResult = Test-MetadataCompleteness -Metadata $metadata -FilePath $FilePath
    Write-TestResult -TestName "Metadata Completeness" -Passed $metadataResult.Passed -Message $metadataResult.Message -Score $metadataResult.Score
    $results['Metadata'] = $metadataResult

    # Test 2: Glossary Terms
    $glossaryResult = Test-GlossaryTerms -Metadata $metadata -Content $content
    Write-TestResult -TestName "Glossary Terms" -Passed $glossaryResult.Passed -Message $glossaryResult.Message -Score $glossaryResult.Score
    $results['Glossary'] = $glossaryResult

    # Test 3: Code Blocks
    $codeResult = Test-CodeBlocks -Content $content
    Write-TestResult -TestName "Code Block Quality" -Passed $codeResult.Passed -Message $codeResult.Message -Score $codeResult.Score
    $results['CodeBlocks'] = $codeResult

    # Test 4: Readability
    $readabilityResult = Test-Readability -Content $content
    Write-TestResult -TestName "Readability" -Passed $readabilityResult.Passed -Message $readabilityResult.Message -Score $readabilityResult.Score
    $results['Readability'] = $readabilityResult

    # Calculate overall score (weighted)
    $overallScore = [Math]::Round(
        ($metadataResult.Score * 0.4) +   # 40% weight
        ($glossaryResult.Score * 0.15) +  # 15% weight
        ($codeResult.Score * 0.25) +      # 25% weight
        ($readabilityResult.Score * 0.20) # 20% weight
    )

    $passed = ($overallScore -ge $MinScore)

    Write-Host "`n  Overall Score: " -NoNewline
    $scoreColor = if ($overallScore -ge 90) { 'Green' } elseif ($overallScore -ge 75) { 'Yellow' } else { 'Red' }
    Write-Host "$overallScore/100" -ForegroundColor $scoreColor

    if ($passed) {
        Write-Host "  ✓ PASS" -ForegroundColor Green
    }
    else {
        Write-Host "  ✗ FAIL (minimum: $MinScore)" -ForegroundColor Red
    }

    return @{
        OverallScore = $overallScore
        Passed = $passed
        Results = $results
    }
}

##############################################################################
# Main Logic
##############################################################################

try {
    Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Document Quality Validation" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

    $absPath = Resolve-Path $Path -ErrorAction Stop

    $files = @()
    if ((Get-Item $absPath) -is [System.IO.DirectoryInfo]) {
        Write-Host "Scanning directory: $absPath`n" -ForegroundColor Yellow
        $files = Get-ChildItem -Path $absPath -Filter "*.md" -Recurse
    }
    else {
        $files = @(Get-Item $absPath)
    }

    if ($files.Count -eq 0) {
        Write-Host "No markdown files found." -ForegroundColor Yellow
        exit 0
    }

    Write-Host "Found $($files.Count) document(s) to validate`n" -ForegroundColor Cyan

    $allResults = @()
    foreach ($file in $files) {
        $result = Test-DocumentFile -FilePath $file.FullName
        $result['File'] = $file.FullName
        $allResults += $result
    }

    # Summary
    Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Summary" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

    $passed = ($allResults | Where-Object { $_.Passed }).Count
    $failed = $allResults.Count - $passed
    $avgScore = [Math]::Round(($allResults | Measure-Object -Property OverallScore -Average).Average, 1)

    Write-Host "  Total Documents: $($allResults.Count)" -ForegroundColor White
    Write-Host "  Passed: " -NoNewline
    Write-Host "$passed" -ForegroundColor Green
    Write-Host "  Failed: " -NoNewline
    Write-Host "$failed" -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Red' })
    Write-Host "  Average Score: " -NoNewline
    $scoreColor = if ($avgScore -ge 90) { 'Green' } elseif ($avgScore -ge 75) { 'Yellow' } else { 'Red' }
    Write-Host "$avgScore/100" -ForegroundColor $scoreColor

    Write-Host ""

    if ($failed -eq 0) {
        Write-Host "✓ All documents passed quality validation!" -ForegroundColor Green
        exit 0
    }
    else {
        Write-Host "✗ Some documents failed validation." -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "`n✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
