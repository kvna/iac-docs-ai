<#
.SYNOPSIS
    Assess documentation quality and generate improvement scores

.DESCRIPTION
    Evaluates documentation files for:
    - Metadata completeness
    - Content quality (structure, clarity)
    - Searchability (keywords, tags)
    - Freshness (last reviewed date)
    - Generates quality scores and improvement recommendations

.PARAMETER DocumentPath
    Path to document or directory to assess (default: docs/)

.PARAMETER OutputFormat
    Output format: console, json, csv, html (default: console)

.PARAMETER MinimumScore
    Minimum acceptable score (0-100). Documents below this score are flagged.

.EXAMPLE
    .\Assess-Documentation-Quality.ps1

.EXAMPLE
    .\Assess-Documentation-Quality.ps1 -DocumentPath "docs/day1" -MinimumScore 70

.EXAMPLE
    .\Assess-Documentation-Quality.ps1 -OutputFormat json > quality-report.json

.NOTES
    Requires: PowerShell 7+
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$DocumentPath,

    [Parameter()]
    [ValidateSet("console", "json", "csv", "html")]
    [string]$OutputFormat = "console",

    [Parameter()]
    [int]$MinimumScore = 70
)

$ErrorActionPreference = 'Stop'

# Default to docs folder
if (-not $DocumentPath) {
    $DocumentPath = Join-Path $PSScriptRoot "..\..\docs"
}

Write-Host "📊 Documentation Quality Assessment" -ForegroundColor Cyan
Write-Host "=" * 60
Write-Host "Scanning: $DocumentPath" -ForegroundColor Gray
Write-Host "Minimum Score: $MinimumScore" -ForegroundColor Gray
Write-Host ""

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

            if ($line -match '^(\w+):\s*(.*)$') {
                if ($currentKey -and $currentArray.Count -gt 0) {
                    $metadata[$currentKey] = $currentArray
                    $currentArray = @()
                }

                $key = $Matches[1]
                $value = $Matches[2].Trim()

                if ($value -match '^\[(.*)\]$') {
                    $arrayContent = $Matches[1]
                    $metadata[$key] = $arrayContent -split ',\s*' | ForEach-Object { $_.Trim().Trim('"').Trim("'") }
                    $currentKey = $null
                }
                elseif ($value -eq '' -or $value -eq $null) {
                    $currentKey = $key
                }
                else {
                    $metadata[$key] = $value.Trim('"').Trim("'")
                    $currentKey = $null
                }
            }
            elseif ($currentKey -and $line -match '^\s*-\s*"?([^"]+)"?\s*$') {
                $currentArray += $Matches[1].Trim()
            }
        }

        if ($currentKey -and $currentArray.Count -gt 0) {
            $metadata[$currentKey] = $currentArray
        }

        return @{
            Metadata = $metadata
            Content = $markdownContent.Trim()
            HasFrontmatter = $true
        }
    }

    return @{
        Metadata = @{}
        Content = $Content
        HasFrontmatter = $false
    }
}

# Function to assess document quality
function Assess-Document {
    param(
        [string]$FilePath
    )

    $content = Get-Content $FilePath -Raw
    $parsed = Parse-YamlFrontmatter -Content $content
    $metadata = $parsed.Metadata
    $bodyContent = $parsed.Content

    $scores = @{
        MetadataCompleteness = 0
        ContentQuality = 0
        Searchability = 0
        Freshness = 0
        Structure = 0
    }

    $issues = @()
    $recommendations = @()

    # 1. Metadata Completeness (30 points)
    $requiredFields = @('document_id', 'document_type', 'skill_level', 'topics', 'technologies', 'estimated_time')
    $optionalFields = @('search_keywords', 'last_reviewed', 'prerequisites', 'learning_outcomes', 'related_documents')

    if (-not $parsed.HasFrontmatter) {
        $issues += "❌ CRITICAL: No YAML frontmatter found"
        $recommendations += "Add YAML frontmatter with metadata"
        $scores.MetadataCompleteness = 0
    }
    else {
        $requiredPresent = 0
        $optionalPresent = 0

        foreach ($field in $requiredFields) {
            if ($metadata.ContainsKey($field) -and $metadata[$field]) {
                $requiredPresent++
            }
            else {
                $issues += "⚠️  Missing required field: $field"
            }
        }

        foreach ($field in $optionalFields) {
            if ($metadata.ContainsKey($field) -and $metadata[$field]) {
                $optionalPresent++
            }
        }

        # Score: Required fields worth 20 points, optional 10 points
        $scores.MetadataCompleteness = ([math]::Round(($requiredPresent / $requiredFields.Count) * 20, 1)) +
                                       ([math]::Round(($optionalPresent / $optionalFields.Count) * 10, 1))
    }

    # 2. Content Quality (25 points)
    $contentScore = 0

    # Has a title (H1)?
    if ($bodyContent -match '^#\s+.+') {
        $contentScore += 5
    }
    else {
        $issues += "⚠️  No H1 title found"
    }

    # Has sections (H2)?
    $h2Count = ([regex]::Matches($bodyContent, '^##\s+.+', [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count
    if ($h2Count -ge 3) {
        $contentScore += 5
    }
    elseif ($h2Count -gt 0) {
        $contentScore += 3
        $recommendations += "Add more sections (H2 headings) for better structure"
    }
    else {
        $issues += "⚠️  No sections (H2 headings) found"
    }

    # Has code examples?
    $codeBlockCount = ([regex]::Matches($bodyContent, '```', [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count / 2
    if ($codeBlockCount -ge 2) {
        $contentScore += 5
    }
    elseif ($codeBlockCount -gt 0) {
        $contentScore += 3
    }

    # Has lists (bullets/numbered)?
    if ($bodyContent -match '^\s*[-*]\s+' -or $bodyContent -match '^\s*\d+\.\s+') {
        $contentScore += 5
    }

    # Length check (too short = incomplete)
    $wordCount = ($bodyContent -split '\s+').Count
    if ($wordCount -lt 100) {
        $issues += "⚠️  Document is very short ($wordCount words)"
        $recommendations += "Expand content with more details and examples"
    }
    elseif ($wordCount -gt 200) {
        $contentScore += 5
    }

    $scores.ContentQuality = $contentScore

    # 3. Searchability (20 points)
    $searchScore = 0

    # Has search keywords?
    if ($metadata['search_keywords'] -and $metadata['search_keywords'].Count -ge 3) {
        $searchScore += 10
    }
    elseif ($metadata['search_keywords']) {
        $searchScore += 5
        $recommendations += "Add more search keywords (at least 5 recommended)"
    }
    else {
        $issues += "⚠️  No search keywords defined"
        $recommendations += "Add search_keywords to YAML frontmatter"
    }

    # Has topics tags?
    if ($metadata['topics'] -and $metadata['topics'].Count -ge 3) {
        $searchScore += 5
    }
    elseif ($metadata['topics']) {
        $searchScore += 2
    }

    # Has technology tags?
    if ($metadata['technologies'] -and $metadata['technologies'].Count -ge 1) {
        $searchScore += 5
    }

    $scores.Searchability = $searchScore

    # 4. Freshness (15 points)
    $freshnessScore = 0

    if ($metadata['last_reviewed']) {
        try {
            $lastReviewed = [DateTime]::Parse($metadata['last_reviewed'])
            $daysSince = ([DateTime]::Now - $lastReviewed).Days

            if ($daysSince -le 30) {
                $freshnessScore = 15
            }
            elseif ($daysSince -le 90) {
                $freshnessScore = 10
                $recommendations += "Document hasn't been reviewed in $daysSince days - consider reviewing"
            }
            elseif ($daysSince -le 180) {
                $freshnessScore = 5
                $issues += "⚠️  Document is $daysSince days old - review recommended"
            }
            else {
                $issues += "❌ Document is $daysSince days old - URGENT review needed"
            }
        }
        catch {
            $issues += "⚠️  last_reviewed date is invalid"
        }
    }
    else {
        $issues += "⚠️  No last_reviewed date"
        $recommendations += "Add last_reviewed date to track document freshness"
    }

    $scores.Freshness = $freshnessScore

    # 5. Structure (10 points)
    $structureScore = 0

    # Has overview/goal section?
    if ($bodyContent -match '(?i)(## Overview|## Goal|## Purpose|## Introduction)') {
        $structureScore += 3
    }

    # Has examples section?
    if ($bodyContent -match '(?i)(## Example|## Examples|## Usage)') {
        $structureScore += 2
    }

    # Has related documents?
    if ($metadata['related_documents'] -and $metadata['related_documents'].Count -gt 0) {
        $structureScore += 3
    }
    else {
        $recommendations += "Add related_documents to help users navigate"
    }

    # Has prerequisites?
    if ($metadata['prerequisites']) {
        $structureScore += 2
    }

    $scores.Structure = $structureScore

    # Calculate total score
    $totalScore = $scores.MetadataCompleteness + $scores.ContentQuality +
                  $scores.Searchability + $scores.Freshness + $scores.Structure

    # Grade
    $grade = switch ($totalScore) {
        {$_ -ge 90} { "A" }
        {$_ -ge 80} { "B" }
        {$_ -ge 70} { "C" }
        {$_ -ge 60} { "D" }
        default { "F" }
    }

    return @{
        FilePath = $FilePath
        FileName = (Get-Item $FilePath).Name
        TotalScore = [math]::Round($totalScore, 1)
        Grade = $grade
        Scores = $scores
        Issues = $issues
        Recommendations = $recommendations
        WordCount = $wordCount
        Metadata = $metadata
    }
}

# Find all markdown files
$docFiles = Get-ChildItem -Path $DocumentPath -Filter "*.md" -Recurse | Where-Object {
    $_.Name -ne "DOCUMENT_MANIFEST.md" -and
    $_.Name -ne "README.md" -and
    $_.Name -notlike "*.draft.md"
}

Write-Host "📁 Found $($docFiles.Count) documents to assess" -ForegroundColor Green
Write-Host ""

# Assess all documents
$results = @()

foreach ($doc in $docFiles) {
    Write-Host "Assessing: $($doc.Name)" -ForegroundColor Gray
    $assessment = Assess-Document -FilePath $doc.FullName
    $results += $assessment
}

# Sort by score (lowest first - need most attention)
$results = $results | Sort-Object -Property TotalScore

# Output results
switch ($OutputFormat) {
    "json" {
        $results | ConvertTo-Json -Depth 10
    }

    "csv" {
        $results | Select-Object FileName, TotalScore, Grade, @{N='Issues';E={$_.Issues -join '; '}} | ConvertTo-Csv -NoTypeInformation
    }

    "html" {
        $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Documentation Quality Report</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        h1 { color: #0078d4; }
        .summary { background: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
        .doc { background: white; padding: 15px; margin-bottom: 15px; border-radius: 8px; border-left: 5px solid #ccc; }
        .grade-A { border-left-color: #28a745; }
        .grade-B { border-left-color: #17a2b8; }
        .grade-C { border-left-color: #ffc107; }
        .grade-D { border-left-color: #fd7e14; }
        .grade-F { border-left-color: #dc3545; }
        .score { font-size: 24px; font-weight: bold; color: #0078d4; }
        .issue { color: #dc3545; margin: 5px 0; }
        .recommendation { color: #17a2b8; margin: 5px 0; }
    </style>
</head>
<body>
    <h1>📊 Documentation Quality Report</h1>
    <div class="summary">
        <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm')</p>
        <p>Total Documents: $($results.Count)</p>
        <p>Average Score: $([math]::Round(($results | Measure-Object -Property TotalScore -Average).Average, 1))</p>
        <p>Documents Below Minimum ($MinimumScore): $(($results | Where-Object {$_.TotalScore -lt $MinimumScore}).Count)</p>
    </div>
"@

        foreach ($result in $results) {
            $html += @"
    <div class="doc grade-$($result.Grade)">
        <h2>$($result.FileName)</h2>
        <p class="score">Score: $($result.TotalScore)/100 (Grade: $($result.Grade))</p>
        <p><strong>Word Count:</strong> $($result.WordCount)</p>

        <h3>Detailed Scores:</h3>
        <ul>
            <li>Metadata Completeness: $($result.Scores.MetadataCompleteness)/30</li>
            <li>Content Quality: $($result.Scores.ContentQuality)/25</li>
            <li>Searchability: $($result.Scores.Searchability)/20</li>
            <li>Freshness: $($result.Scores.Freshness)/15</li>
            <li>Structure: $($result.Scores.Structure)/10</li>
        </ul>

"@
            if ($result.Issues.Count -gt 0) {
                $html += "        <h3>Issues:</h3><ul>"
                foreach ($issue in $result.Issues) {
                    $html += "            <li class='issue'>$issue</li>"
                }
                $html += "        </ul>"
            }

            if ($result.Recommendations.Count -gt 0) {
                $html += "        <h3>Recommendations:</h3><ul>"
                foreach ($rec in $result.Recommendations) {
                    $html += "            <li class='recommendation'>$rec</li>"
                }
                $html += "        </ul>"
            }

            $html += "    </div>"
        }

        $html += @"
</body>
</html>
"@
        $html
    }

    default {  # console
        Write-Host ""
        Write-Host "=" * 60
        Write-Host "📊 QUALITY ASSESSMENT SUMMARY" -ForegroundColor Cyan
        Write-Host "=" * 60

        $avgScore = ($results | Measure-Object -Property TotalScore -Average).Average
        $belowMinimum = ($results | Where-Object {$_.TotalScore -lt $MinimumScore}).Count

        Write-Host ""
        Write-Host "Total Documents: $($results.Count)" -ForegroundColor White
        Write-Host "Average Score: $([math]::Round($avgScore, 1))/100" -ForegroundColor White
        Write-Host "Below Minimum ($MinimumScore): $belowMinimum" -ForegroundColor $(if ($belowMinimum -gt 0) { "Yellow" } else { "Green" })
        Write-Host ""

        Write-Host "=" * 60
        Write-Host "📄 DOCUMENT SCORES (Lowest to Highest)" -ForegroundColor Cyan
        Write-Host "=" * 60

        foreach ($result in $results) {
            Write-Host ""
            Write-Host "Document: " -ForegroundColor Gray -NoNewline
            Write-Host $result.FileName -ForegroundColor White

            $scoreColor = switch ($result.Grade) {
                "A" { "Green" }
                "B" { "Cyan" }
                "C" { "Yellow" }
                "D" { "DarkYellow" }
                "F" { "Red" }
            }

            Write-Host "Score: " -ForegroundColor Gray -NoNewline
            Write-Host "$($result.TotalScore)/100 " -ForegroundColor $scoreColor -NoNewline
            Write-Host "(Grade: $($result.Grade))" -ForegroundColor $scoreColor

            Write-Host "Word Count: $($result.WordCount)" -ForegroundColor Gray

            Write-Host "`nBreakdown:" -ForegroundColor Gray
            Write-Host "  Metadata: $($result.Scores.MetadataCompleteness)/30" -ForegroundColor Gray
            Write-Host "  Content: $($result.Scores.ContentQuality)/25" -ForegroundColor Gray
            Write-Host "  Search: $($result.Scores.Searchability)/20" -ForegroundColor Gray
            Write-Host "  Fresh: $($result.Scores.Freshness)/15" -ForegroundColor Gray
            Write-Host "  Structure: $($result.Scores.Structure)/10" -ForegroundColor Gray

            if ($result.Issues.Count -gt 0) {
                Write-Host "`nIssues:" -ForegroundColor Red
                foreach ($issue in $result.Issues) {
                    Write-Host "  $issue" -ForegroundColor Yellow
                }
            }

            if ($result.Recommendations.Count -gt 0) {
                Write-Host "`nRecommendations:" -ForegroundColor Cyan
                foreach ($rec in $result.Recommendations) {
                    Write-Host "  • $rec" -ForegroundColor Gray
                }
            }

            Write-Host "-" * 60
        }

        Write-Host ""
        Write-Host "=" * 60
        Write-Host "✅ Assessment Complete!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Documents needing attention:" -ForegroundColor Yellow
        $needsAttention = $results | Where-Object {$_.TotalScore -lt $MinimumScore}
        if ($needsAttention.Count -eq 0) {
            Write-Host "  None - all documents meet minimum quality!" -ForegroundColor Green
        }
        else {
            foreach ($doc in $needsAttention) {
                Write-Host "  • $($doc.FileName) (Score: $($doc.TotalScore))" -ForegroundColor Yellow
            }
        }

        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "  1. Review documents with lowest scores" -ForegroundColor Gray
        Write-Host "  2. Address critical issues first (❌)" -ForegroundColor Gray
        Write-Host "  3. Add missing metadata" -ForegroundColor Gray
        Write-Host "  4. Re-run assessment weekly" -ForegroundColor Gray
        Write-Host ""
    }
}
