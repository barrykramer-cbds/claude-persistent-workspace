#!/usr/bin/env bash
#
# setup.sh - Creates a Claude Persistent Workspace directory structure
#
# Usage: ./setup.sh [target_path]
#   target_path: Where to create the workspace (default: current directory)

set -euo pipefail

TARGET="${1:-.}"
TARGET="$(cd "$(dirname "$TARGET")" && pwd)/$(basename "$TARGET")"

echo "Creating Claude Persistent Workspace at: $TARGET"
echo ""

# Create directory structure
dirs=(
    "$TARGET"
    "$TARGET/raw"
    "$TARGET/raw/samples"
    "$TARGET/raw/external"
    "$TARGET/raw/uploads"
    "$TARGET/analysis"
    "$TARGET/analysis/catalogs"
    "$TARGET/analysis/validation"
    "$TARGET/analysis/models"
    "$TARGET/deliverables"
    "$TARGET/deliverables/drafts"
    "$TARGET/deliverables/final"
    "$TARGET/snapshots"
    "$TARGET/scripts"
)

for dir in "${dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo "  Created: $dir"
    else
        echo "  Exists:  $dir"
    fi
done

# Create session state file
STATE_FILE="$TARGET/.session_state.md"
if [ ! -f "$STATE_FILE" ]; then
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    cat > "$STATE_FILE" << EOF
# Session State
## Last Updated: $TIMESTAMP
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
EOF
    echo "  Created: $STATE_FILE"
else
    echo "  Exists:  $STATE_FILE (not overwritten)"
fi

echo ""
echo "Workspace ready."
echo ""
echo "Next steps:"
echo "  1. Ensure Filesystem MCP is configured with access to: $TARGET"
echo "  2. Start a Claude conversation and ask it to read .session_state.md"
echo "  3. Begin your analysis work"
