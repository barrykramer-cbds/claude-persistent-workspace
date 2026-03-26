# Claude Persistent Workspace

A local filesystem workspace pattern for Claude that provides persistent project state across conversation sessions without sacrificing access to conversation history search.

## The Problem

Anthropic's built-in Projects feature gives you persistent context across sessions. The tradeoff: it isolates your conversation from general history search tools (`conversation_search` and `recent_chats`). For analytical work that needs both persistent state AND dynamic evidence gathering from past conversations, this is a forced choice that degrades output quality.

## The Solution

A local directory structure on your machine, accessible via the Filesystem MCP, that functions as a persistent project workspace. Files written during one conversation persist on disk. Any future conversation can read them through the same MCP connection. Because you never enter a Project boundary, your full conversation search access is preserved.

You get persistence AND search. No tradeoff.

## Prerequisites

- **Claude Desktop** or any Claude interface with MCP support
- **Filesystem MCP** configured and connected, with access to the directory where you'll create your workspace
- **Git** (optional, for version control)

## Quick Start

### Windows (PowerShell)

```powershell
# Clone the repo
git clone https://github.com/barrykramer-cbds/claude-persistent-workspace.git C:\Dev\claude-persistent-workspace

# Or run the setup script standalone to create a fresh workspace anywhere
.\setup.ps1 -Path "C:\Projects\my-research-workspace"
```

### macOS / Linux (Bash)

```bash
# Clone the repo
git clone https://github.com/barrykramer-cbds/claude-persistent-workspace.git ~/dev/claude-persistent-workspace

# Or run the setup script standalone
chmod +x setup.sh
./setup.sh ~/projects/my-research-workspace
```

### Then in Claude

Start a new conversation and say:

> "Read the file at [YOUR_PATH]/.session_state.md and let's pick up where we left off."

That's it. Claude reads the state file, understands where the work stands, and continues.

## How It Works

### Session State Management

The `.session_state.md` file at the workspace root is the handoff mechanism between sessions. The protocol:

1. **Start of session** -- Claude reads `.session_state.md` to understand current state
2. **During session** -- Claude reads and writes files in the workspace as needed
3. **End of session** -- Claude updates `.session_state.md` with what was accomplished, what changed, and what the next session should prioritize

### Directory Structure

```
claude-workspace/
├── .session_state.md          # Current analysis state (read first every session)
├── raw/                       # Primary source data
│   ├── samples/               # Conversation excerpts, writing samples, evidence
│   ├── external/              # Third-party data, research, reference material
│   └── uploads/               # Files you drop in between sessions
├── analysis/                  # Work in progress
│   ├── catalogs/              # Pattern catalogs, taxonomies, inventories
│   ├── validation/            # Testing scripts and results
│   └── models/                # Frameworks, difference models, mappings
├── deliverables/              # Output documents
│   ├── drafts/                # Work in progress deliverables
│   └── final/                 # Completed, versioned deliverables
├── snapshots/                 # Timestamped state captures
│   └── YYYY-MM-DD/            # Dated snapshot directories
└── scripts/                   # Utility scripts
```

### Snapshots

For temporal analysis (tracking how work evolves), copy key files into `snapshots/YYYY-MM-DD/` at any point. Snapshots are read-only records. Comparing snapshots across dates shows how your analysis developed over time.

### File Naming Conventions

- `snake_case` for all filenames
- Prefix with category: `raw_`, `analysis_`, `deliverable_`, `script_`
- Version deliverables: `_v1`, `_v2`
- Date-stamp raw data: `raw_sample_technical_2026-03-26.md`

## Use Cases

- Multi-session research projects
- Long-running analytical work
- Iterative document building across conversations
- Any work where Claude needs to "remember" across sessions without losing conversation search access
- Collaborative studies requiring persistent evidence libraries and pattern catalogs

## Why Not Just Use Projects?

Projects work well when your entire workflow lives inside the project boundary and you don't need to reference conversations outside it. This workspace pattern is for situations where you need both: the persistence of a project space AND the ability to search your full conversation history for evidence, prior analysis, or context that lives outside the current project scope.

The two approaches are complementary. Use Projects for self-contained work. Use this workspace for work that spans your full conversation history.

## Architecture Notes

The Filesystem MCP is the only required integration. Claude reads and writes directly to your local filesystem. No cloud storage, no API keys, no external dependencies. Your data stays on your machine.

The workspace is just a directory convention plus a session state protocol. The value comes from the pattern, not from any particular technology.

## License

MIT License. See [LICENSE](LICENSE) for details.

## Author

Built by Barry Kramer -- fractional CAISO and Senior vCISO with 40+ years in IT and 30+ years in information security. This tool emerged from practical needs during multi-session AI-assisted analytical work and is published as a general-purpose framework for anyone doing sustained research or analysis with Claude.
