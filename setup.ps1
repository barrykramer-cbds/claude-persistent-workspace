<#
.SYNOPSIS
    Creates a Claude Persistent Workspace directory structure.

.DESCRIPTION
    Sets up the full directory scaffold and template files for a local
    Claude workspace that provides persistent state across conversation
    sessions via the Filesystem MCP.

.PARAMETER Path
    The target directory path where the workspace will be created.
    Defaults to the current directory.

.EXAMPLE
    .\setup.ps1 -Path "C:\Projects\my-research"
#>

param(
    [Parameter(Position=0)]
    [string]$Path = (Get-Location).Path
)

$ErrorActionPreference = "Stop"

# Resolve to absolute path
$Path = [System.IO.Path]::GetFullPath($Path)

Write-Host "Creating Claude Persistent Workspace at: $Path" -ForegroundColor Cyan
Write-Host ""

# Create directory structure
$dirs = @(
    $Path,
    "$Path\raw",
    "$Path\raw\samples",
    "$Path\raw\external",
    "$Path\raw\uploads",
    "$Path\analysis",
    "$Path\analysis\catalogs",
    "$Path\analysis\validation",
    "$Path\analysis\models",
    "$Path\deliverables",
    "$Path\deliverables\drafts",
    "$Path\deliverables\final",
    "$Path\snapshots",
    "$Path\scripts"
)

foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  Created: $dir" -ForegroundColor Green
    } else {
        Write-Host "  Exists:  $dir" -ForegroundColor Yellow
    }
}

# Create session state file
$sessionStatePath = "$Path\.session_state.md"
if (-not (Test-Path $sessionStatePath)) {
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"
    $sessionState = @"
# Session State
## Last Updated: $timestamp
## Last Session Summary
Workspace initialized. No analysis sessions have been conducted yet.

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
"@
    Set-Content -Path $sessionStatePath -Value $sessionState -Encoding UTF8
    Write-Host "  Created: $sessionStatePath" -ForegroundColor Green
} else {
    Write-Host "  Exists:  $sessionStatePath (not overwritten)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Workspace ready." -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. Ensure Filesystem MCP is configured with access to: $Path" -ForegroundColor White
Write-Host "  2. Start a Claude conversation and ask it to read .session_state.md" -ForegroundColor White
Write-Host "  3. Begin your analysis work" -ForegroundColor White
