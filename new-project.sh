#!/usr/bin/env bash
#
# new-project.sh - Creates a new Local Project workspace with a single command
#
# A "Local Project" is a filesystem workspace accessed via the Filesystem MCP
# that provides persistent state across Claude sessions without sacrificing
# conversation history search. Distinct from Anthropic's "Claude Projects."
#
# Usage: ./new-project.sh <project-name> [description] [workspaces-root]
#   project-name:    Required. Used as directory name (sanitized to lowercase+hyphens)
#   description:     Optional. Brief project description for registry and state file
#   workspaces-root: Optional. Parent directory for all projects (default: ~/dev/workspaces)

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <project-name> [description] [workspaces-root]"
    echo ""
    echo "Examples:"
    echo "  $0 spec-economy \"Specification Economy whitepaper research\""
    echo "  $0 kalina-case \"Pig butchering investigation\" ~/projects/workspaces"
    exit 1
fi

NAME="$1"
DESCRIPTION="${2:-}"
WORKSPACES_ROOT="${3:-$HOME/dev/workspaces}"

# Normalize: lowercase, spaces to hyphens, strip non-alphanumeric
SAFE_NAME=$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')

if [ -z "$SAFE_NAME" ]; then
    echo "Error: Project name '$NAME' produces an empty directory name after sanitization."
    exit 1
fi

PROJECT_PATH="$WORKSPACES_ROOT/$SAFE_NAME"

if [ -d "$PROJECT_PATH" ]; then
    echo "Error: Project directory already exists at: $PROJECT_PATH"
    echo "Use a different name or remove the existing directory."
    exit 1
fi

mkdir -p "$WORKSPACES_ROOT"

echo ""
echo "Creating Local Project: $SAFE_NAME"
echo "Location: $PROJECT_PATH"
[ -n "$DESCRIPTION" ] && echo "Description: $DESCRIPTION"
echo ""

# Create directory structure
dirs=(
    "$PROJECT_PATH"
    "$PROJECT_PATH/context"
    "$PROJECT_PATH/raw"
    "$PROJECT_PATH/raw/samples"
    "$PROJECT_PATH/raw/external"
    "$PROJECT_PATH/raw/uploads"
    "$PROJECT_PATH/analysis"
    "$PROJECT_PATH/analysis/catalogs"
    "$PROJECT_PATH/analysis/validation"
    "$PROJECT_PATH/analysis/models"
    "$PROJECT_PATH/deliverables"
    "$PROJECT_PATH/deliverables/drafts"
    "$PROJECT_PATH/deliverables/final"
    "$PROJECT_PATH/snapshots"
    "$PROJECT_PATH/scripts"
)

for dir in "${dirs[@]}"; do
    mkdir -p "$dir"
    echo "  Created: $dir"
done

# Create context manifest
cat > "$PROJECT_PATH/context/manifest.md" << 'MANIFEST'
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
MANIFEST
echo "  Created: $PROJECT_PATH/context/manifest.md"

# Create session state file
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
DESC_LINE="${DESCRIPTION:-No description provided.}"

cat > "$PROJECT_PATH/.session_state.md" << EOF
# Session State
## Project: $NAME
## Last Updated: $TIMESTAMP

## Session Start Protocol
1. Read this file first
2. Read context/manifest.md to see available project knowledge
3. Load specific context files as needed during the session
4. Update this file before the session ends

## Last Session Summary
Local Project initialized. No analysis sessions have been conducted yet.

## Project Description
$DESC_LINE

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
EOF
echo "  Created: $PROJECT_PATH/.session_state.md"

# Update or create registry
REGISTRY_PATH="$WORKSPACES_ROOT/.registry.md"

if [ ! -f "$REGISTRY_PATH" ]; then
    cat > "$REGISTRY_PATH" << 'REGISTRY'
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
REGISTRY
fi

# Insert new project row after the first table header separator in Active Projects
DATE_STAMP=$(date +"%Y-%m-%d")
NEW_ROW="| $SAFE_NAME | \`$PROJECT_PATH\` | $DATE_STAMP | active | $DESC_LINE |"

# Use awk for reliable insertion after the first separator line
awk -v row="$NEW_ROW" '/^\|---.*\|---.*\|---.*\|---.*\|---/ && !done { print; print row; done=1; next } { print }' "$REGISTRY_PATH" > "${REGISTRY_PATH}.tmp" && mv "${REGISTRY_PATH}.tmp" "$REGISTRY_PATH"

echo "  Registered in: $REGISTRY_PATH"

echo ""
echo "Local Project '$SAFE_NAME' is ready."
echo ""
echo "To start working:"
echo "  Open Claude and say:"
echo "  'Read $WORKSPACES_ROOT/$SAFE_NAME/.session_state.md and let's get started.'"
echo ""
echo "To add project knowledge:"
echo "  Drop files into: $PROJECT_PATH/context/"
echo "  Update the manifest: $PROJECT_PATH/context/manifest.md"
echo ""
echo "Or to see all projects:"
echo "  'Read $WORKSPACES_ROOT/.registry.md and show me my Local Projects.'"
