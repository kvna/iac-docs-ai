<#
.SYNOPSIS
    Report gaps, issues, or questions about documentation

.DESCRIPTION
    Allows team members to:
    - Report missing documentation
    - Flag outdated or incorrect content
    - Ask questions that aren't answered by existing docs
    - Suggest improvements

    Reports are saved to docs/gaps/ for team review and action.

.PARAMETER Type
    Type of report: gap, issue, question, improvement

.PARAMETER Title
    Short title/summary

.PARAMETER Description
    Detailed description

.PARAMETER RelatedDocument
    Related document (if applicable)

.PARAMETER Priority
    Priority: low, medium, high, critical

.EXAMPLE
    .\Report-Documentation-Gap.ps1 -Type gap -Title "No docs on CI/CD" -Description "We need documentation on setting up Terraform CI/CD pipeline"

.EXAMPLE
    .\Report-Documentation-Gap.ps1 -Type issue -Title "Outdated Azure CLI version" -RelatedDocument "howto-environment-setup.md" -Description "Doc says v2.40+ but we need v2.50+"

.NOTES
    Requires: PowerShell 7+
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("gap", "issue", "question", "improvement")]
    [string]$Type,

    [Parameter(Mandatory = $true)]
    [string]$Title,

    [Parameter(Mandatory = $true)]
    [string]$Description,

    [Parameter()]
    [string]$RelatedDocument,

    [Parameter()]
    [ValidateSet("low", "medium", "high", "critical")]
    [string]$Priority = "medium"
)

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "📝 Documentation Gap Report" -ForegroundColor Cyan
Write-Host "=" * 60

# Create gaps directory if it doesn't exist
$gapsDir = Join-Path $PSScriptRoot "..\..\docs\gaps"
if (-not (Test-Path $gapsDir)) {
    New-Item -ItemType Directory -Path $gapsDir | Out-Null
}

# Generate report ID
$reportId = "gap-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$reportFile = Join-Path $gapsDir "$reportId.md"

# Get current user
$currentUser = $env:USERNAME
if (-not $currentUser) {
    $currentUser = $env:USER
}

# Create report content
$reportContent = @"
---
report_id: $reportId
type: $Type
priority: $Priority
status: open
reported_by: $currentUser
reported_date: $(Get-Date -Format 'yyyy-MM-dd')
related_document: $RelatedDocument
---

# $Title

## Type
**$($Type.ToUpper())** - Priority: **$Priority**

## Description

$Description

## Related Documentation
$(if ($RelatedDocument) { "- [$RelatedDocument]($RelatedDocument)" } else { "None specified" })

## Suggested Action

<!-- Team: Please fill in suggested action -->

**For gaps:** Create new document or section
**For issues:** Update existing document
**For questions:** Answer here or update docs to address
**For improvements:** Review and implement if beneficial

## Assignment

- [ ] Assigned to: _______
- [ ] Target completion: _______
- [ ] Reviewer: _______

## Resolution

<!-- Fill in when resolved -->

**Status:** Open
**Resolved by:**
**Resolution date:**
**Changes made:**

---

## Team Discussion

<!-- Add comments below -->

"@

# Save report
$reportContent | Set-Content -Path $reportFile -Encoding UTF8

Write-Host ""
Write-Host "✅ Gap report created!" -ForegroundColor Green
Write-Host ""
Write-Host "Report ID: " -ForegroundColor Gray -NoNewline
Write-Host $reportId -ForegroundColor Cyan
Write-Host "File: " -ForegroundColor Gray -NoNewline
Write-Host $reportFile -ForegroundColor White
Write-Host ""
Write-Host "Type: " -ForegroundColor Gray -NoNewline

$typeColor = switch ($Type) {
    "gap" { "Yellow" }
    "issue" { "Red" }
    "question" { "Cyan" }
    "improvement" { "Green" }
}
Write-Host $Type.ToUpper() -ForegroundColor $typeColor -NoNewline
Write-Host " | Priority: " -ForegroundColor Gray -NoNewline

$priorityColor = switch ($Priority) {
    "critical" { "Red" }
    "high" { "DarkYellow" }
    "medium" { "Yellow" }
    "low" { "Gray" }
}
Write-Host $Priority.ToUpper() -ForegroundColor $priorityColor

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Team will review this report" -ForegroundColor Gray
Write-Host "  2. Report will be assigned to a team member" -ForegroundColor Gray
Write-Host "  3. Documentation will be created/updated" -ForegroundColor Gray
Write-Host "  4. You'll be notified when resolved" -ForegroundColor Gray
Write-Host ""
Write-Host "Track all reports:" -ForegroundColor Cyan
Write-Host "  pwsh scripts/quality/List-Documentation-Gaps.ps1" -ForegroundColor White
Write-Host ""

# Also create a summary file if it doesn't exist
$summaryFile = Join-Path $gapsDir "README.md"
if (-not (Test-Path $summaryFile)) {
    $summaryContent = @"
# Documentation Gap Reports

This directory contains reports of documentation gaps, issues, questions, and improvement suggestions from the team.

## How to Report

Use the gap reporting script:

\`\`\`powershell
# Report missing documentation
pwsh scripts/quality/Report-Documentation-Gap.ps1 -Type gap -Title "Title" -Description "Details"

# Report an issue in existing docs
pwsh scripts/quality/Report-Documentation-Gap.ps1 -Type issue -Title "Title" -Description "Details" -RelatedDocument "filename.md"

# Ask a question
pwsh scripts/quality/Report-Documentation-Gap.ps1 -Type question -Title "Title" -Description "Details"

# Suggest an improvement
pwsh scripts/quality/Report-Documentation-Gap.ps1 -Type improvement -Title "Title" -Description "Details"
\`\`\`

## Review Process

1. **Weekly Review**: Team reviews all open reports
2. **Assignment**: Reports are assigned to team members
3. **Action**: Documentation is created/updated
4. **Validation**: Changes are reviewed
5. **Closure**: Report is marked as resolved

## Report Types

- **gap**: Missing documentation
- **issue**: Incorrect or outdated content
- **question**: Unanswered question
- **improvement**: Enhancement suggestion

## Priority Levels

- **critical**: Blocking work
- **high**: Important, needed soon
- **medium**: Normal priority
- **low**: Nice to have

## All Reports

$(Get-ChildItem -Path $gapsDir -Filter "gap-*.md" | Sort-Object LastWriteTime -Descending | ForEach-Object {
    "- [$($_.BaseName)]($($_.Name))"
})
"@
    $summaryContent | Set-Content -Path $summaryFile -Encoding UTF8
}
