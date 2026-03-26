# Context Manifest
# This file indexes all reference documents in the context/ directory.
# Claude reads this manifest at session start to know what project knowledge is available.
# Files are loaded on demand during the session, not all at once.
#
# Drop files into context/ between sessions. Update this manifest to describe them.
# Claude will discover new files but works better when the manifest is current.
#
# IMPORTANT: context/ is your project's persistent knowledge base.
# Think of it like Anthropic's Claude Project file uploads, but local and token-efficient.
# Claude reads this manifest first, then selectively loads only what the current session needs.
# This avoids wasting context window tokens on reference material that isn't relevant.
#
# Usage:
# - Drop any file Claude should know about into context/
# - Add a row to the table below describing it
# - At session start, Claude reads this manifest and loads files as needed

## Available Context Files

| File | Size | Description |
|------|------|-------------|
