<#
.SYNOPSIS
    Creates a new Local Project workspace with a single command.

.DESCRIPTION
    Scaffolds a complete Local Project directory structure under the workspaces
    root directory and registers it in the project registry. A "Local Project"
    is a filesystem workspace accessed via the Filesystem MCP that provides
    persistent state across Claude conversation sessions without sacrificing
    access to conversation history search.

    This is distinct from Anthropic's built-in "Claude Projects" feature, which
    provides persistent context but isolates the conversation from search tools.

.PARAMETER Name
    The project name. Used as the directory name (will be converted to lowercase
    with hyphens). Required.

.PARAMETER Description
    A brief description of the project. Used in the registry and session state.
    Optional but recommended.

.PARAMETER WorkspacesRoot
    The parent directory where all Local Projects live.
    Defaults to C:\Dev\workspaces on Windows.

.EXAMPLE
    .\new-project.ps1 -Name "spec-economy" -Description "Specification Economy whitepaper research"

.EXAMPLE
    .\new-project.ps1 "kalina-case" "Pig butchering investigation case study"

.EXAMPLE
    .\new-project.ps1 -Name "my-research" -WorkspacesRoot "D:\Projects\workspaces"
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Name,

    [Parameter(Position=1)]
    [string]$Description = "",

    [Parameter()]
    [string]$WorkspacesRoot = "C:\Dev\workspaces"
)

$ErrorActionPreference = "Stop"

# Normalize project name: lowercase, replace spaces with hyphens, strip non-alphanumeric
$SafeName = $Name.ToLower() -replace '\s+', '-' -replace '[^a-z0-9\-]', ''

if ([string]::IsNullOrWhiteSpace($SafeName)) {
    Write-Host "Error: Project name '$Name' produces an empty directory name after sanitization." -ForegroundColor Red
    exit 1
}

$ProjectPath = Join-Path $WorkspacesRoot $SafeName

# Check if project already exists
if (Test-Path $ProjectPath) {
    Write-Host "Error: Project directory already exists at: $ProjectPath" -ForegroundColor Red
    Write-Host "Use a different name or remove the existing directory." -ForegroundColor Yellow
    exit 1
}

# Ensure workspaces root exists
if (-not (Test-Path $WorkspacesRoot)) {
    New-Item -ItemType Directory -Path $WorkspacesRoot -Force | Out-Null
    Write-Host "Created workspaces root: $WorkspacesRoot" -ForegroundColor Cyan
}

Write-Host "" -ForegroundColor Cyan
Write-Host "Creating Local Project: $SafeName" -ForegroundColor Cyan
Write-Host "Location: $ProjectPath" -ForegroundColor Cyan
if ($Description) { Write-Host "Description: $Description" -ForegroundColor Cyan }
Write-Host ""

# Create directory structure
$dirs = @(
    $ProjectPath,
    "$ProjectPath\context",
    "$ProjectPath\raw",
    "$ProjectPath\raw\samples",
    "$ProjectPath\raw\external",
    "$ProjectPath\raw\uploads",
    "$ProjectPath\analysis",
    "$ProjectPath\analysis\catalogs",
    "$ProjectPath\analysis\validation",
    "$ProjectPath\analysis\models",
    "$ProjectPath\deliverables",
    "$ProjectPath\deliverables\drafts",
    "$ProjectPath\deliverables\final",
    "$ProjectPath\snapshots",
    "$ProjectPath\scripts"
)

foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Write-Host "  Created: $dir" -ForegroundColor Green
}

# Create context manifest
$manifestContent = @"
# Context Manifest
# This file indexes all reference documents in the context/ directory.
# Claude reads this manifest at session start to know what project knowledge is available.
# Files are loaded on demand during the session, not all at once.
#
# Drop files into context/ between sessions. Update this manifest to describe them.
# Claude will discover new files but works better when the manifest is current.

## Available Context Files

| File | Size | Description |
|------|------|-------------|
"@
$manifestPath = "$ProjectPath\context\manifest.md"
Set-Content -Path $manifestPath -Value $manifestContent -Encoding UTF8
Write-Host "  Created: $manifestPath" -ForegroundColor Green

# Create session state file
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"
$descLine = if ($Description) { $Description } else { "No description provided." }
$sessionState = @"
# Session State
## Project: $Name
## Last Updated: $timestamp

## Session Start Protocol
1. Read this file first
2. Read context/manifest.md to see available project knowledge
3. Load specific context files as needed during the session
4. Update this file before the session ends

## Last Session Summary
Local Project initialized. No analysis sessions have been conducted yet.

## Project Description
$descLine

## Current Analysis State
Fresh workspace. Ready for project data and first analysis session.

## Completed Deliverables
None yet.

## In-Progress Work
None yet.

## Evidence Gaps
No data has been loaded into the workspace.

## Next Session Priorities
1. Load primary source data into raw/
2. Define the analysis scope and objectives
3. Begin initial analysis pass

## Pivot Log
No pivots recorded.

## File Manifest
- .session_state.md (this file) - Session handoff state
- context/manifest.md - Index of project knowledge files
"@

$sessionStatePath = "$ProjectPath\.session_state.md"
Set-Content -Path $sessionStatePath -Value $sessionState -Encoding UTF8
Write-Host "  Created: $sessionStatePath" -ForegroundColor Green

# Update registry
$registryPath = Join-Path $WorkspacesRoot ".registry.md"

if (-not (Test-Path $registryPath)) {
    $registryContent = @"
# Local Project Registry
# This file is the index of all Local Project workspaces managed by claude-persistent-workspace.
# Claude reads this file to know what projects exist, where they live, and their current status.
#
# "Local Project" = a filesystem workspace managed by this tool via the Filesystem MCP.
# "Claude Project" = Anthropic's built-in Projects feature (persistent context, but no conversation search).

## Active Projects

| Project | Path | Created | Status | Description |
|---------|------|---------|--------|-------------|

## Archived Projects

| Project | Path | Created | Archived | Description |
|---------|------|---------|----------|-------------|
"@
    Set-Content -Path $registryPath -Value $registryContent -Encoding UTF8
}

# Insert new project row after the Active Projects table header separator
$dateStamp = Get-Date -Format "yyyy-MM-dd"
$newRow = "| $SafeName | ``$ProjectPath`` | $dateStamp | active | $descLine |"
$lines = Get-Content -Path $registryPath
$output = @()
$inserted = $false
foreach ($line in $lines) {
    $output += $line
    if (-not $inserted -and $line -match '^\|---.*\|---.*\|---.*\|---.*\|---') {
        $output += $newRow
        $inserted = $true
    }
}
Set-Content -Path $registryPath -Value $output -Encoding UTF8

if ($inserted) {
    Write-Host "  Registered in: $registryPath" -ForegroundColor Green
} else {
    Write-Host "  Warning: Could not find table header in registry. Row not inserted." -ForegroundColor Yellow
    Write-Host "  You may need to manually add this project to: $registryPath" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Local Project '$SafeName' is ready." -ForegroundColor Cyan
Write-Host ""
Write-Host "To start working:" -ForegroundColor White
Write-Host "  Open Claude and say:" -ForegroundColor White
Write-Host "  'Read $WorkspacesRoot\$SafeName\.session_state.md and let's get started.'" -ForegroundColor Yellow
Write-Host ""
Write-Host "To add project knowledge:" -ForegroundColor White
Write-Host "  Drop files into: $ProjectPath\context\" -ForegroundColor White
Write-Host "  Update the manifest: $ProjectPath\context\manifest.md" -ForegroundColor Yellow
Write-Host ""
Write-Host "Or to see all projects:" -ForegroundColor White
Write-Host "  'Read $WorkspacesRoot\.registry.md and show me my Local Projects.'" -ForegroundColor Yellow
