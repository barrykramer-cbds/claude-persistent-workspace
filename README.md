# Claude Persistent Workspace

A local filesystem workspace pattern for Claude that provides persistent project state across conversation sessions without sacrificing access to conversation history search.

This tool creates **Local Projects** -- persistent workspaces on your machine managed through the Filesystem MCP. These are distinct from **Claude Projects** (Anthropic's built-in feature), which provide persistent context but isolate your conversation from history search tools. The two approaches are complementary.

## The Problem

Anthropic's Claude Projects give you persistent context across sessions. The tradeoff: they isolate your conversation from general history search tools (`conversation_search` and `recent_chats`). For analytical work that needs both persistent state AND dynamic evidence gathering from past conversations, this is a forced choice that degrades output quality.

## The Solution

Local Project workspaces on your machine, accessed via the Filesystem MCP. Files written during one conversation persist on disk. Any future conversation can read them through the same MCP connection. Because you never enter a Claude Project boundary, your full conversation search access is preserved.

You get persistence AND search. No tradeoff.

## Prerequisites

- **Claude Desktop** or any Claude interface with MCP support
- **Filesystem MCP** configured and connected, with access to the directory where your workspaces will live
- **Git** (optional, for version control)

## Quick Start

### 1. Clone the Framework

```powershell
# Windows
git clone https://github.com/barrykramer-cbds/claude-persistent-workspace.git C:\Dev\claude-persistent-workspace
```

```bash
# macOS / Linux
git clone https://github.com/barrykramer-cbds/claude-persistent-workspace.git ~/dev/claude-persistent-workspace
```

### 2. Create a Local Project

```powershell
# Windows
cd C:\Dev\claude-persistent-workspace
.\new-project.ps1 -Name "my-research" -Description "Research project on quantum decoherence"
```

```bash
# macOS / Linux
cd ~/dev/claude-persistent-workspace
./new-project.sh my-research "Research project on quantum decoherence"
```

This creates a fully scaffolded workspace at `C:\Dev\workspaces\my-research` (or `~/dev/workspaces/my-research`) and registers it in the project registry.

### 3. Start Working

Open a Claude conversation and say:

> "Read C:\Dev\workspaces\my-research\.session_state.md and let's get started."

Or to see all your projects:

> "Read C:\Dev\workspaces\.registry.md and show me my Local Projects."

## How It Works

### Local Projects vs Claude Projects

| | Local Projects (this tool) | Claude Projects (Anthropic) |
|---|---|---|
| Persistence | Files on your local disk | Anthropic's project context |
| Conversation search | Full access preserved | Isolated from history |
| Data location | Your machine only | Anthropic's servers |
| Setup | Filesystem MCP required | Built into Claude |
| Best for | Multi-session research needing history access | Self-contained work within a project boundary |

Use Claude Projects for self-contained work. Use Local Projects for work that spans your full conversation history.

### Multi-Project Management

The `new-project` script creates independent workspaces under a shared root directory and maintains a registry file:

```
C:\Dev\workspaces\                   (or ~/dev/workspaces/)
    .registry.md                     # Index of all Local Projects
    my-research/                     # Project 1
    spec-economy/                    # Project 2
    case-study/                      # Project 3
```

Claude reads `.registry.md` to know what projects exist, where they live, and their status. You switch between projects by pointing Claude at the right `.session_state.md` file.

### Session State Management

The `.session_state.md` file at each workspace root is the handoff mechanism between sessions:

1. **Start of session** -- Claude reads `.session_state.md` to understand current state
2. **During session** -- Claude reads and writes files in the workspace as needed
3. **End of session** -- Claude updates `.session_state.md` with what was accomplished, what changed, and what the next session should prioritize

### Project Directory Structure

Each Local Project gets this scaffold:

```
project-name/
|-- .session_state.md          # Current analysis state (read first every session)
|-- raw/                       # Primary source data
|   |-- samples/               # Conversation excerpts, writing samples, evidence
|   |-- external/              # Third-party data, research, reference material
|   |-- uploads/               # Files you drop in between sessions
|-- analysis/                  # Work in progress
|   |-- catalogs/              # Pattern catalogs, taxonomies, inventories
|   |-- validation/            # Testing scripts and results
|   |-- models/                # Frameworks, difference models, mappings
|-- deliverables/              # Output documents
|   |-- drafts/                # Work in progress deliverables
|   |-- final/                 # Completed, versioned deliverables
|-- snapshots/                 # Timestamped state captures
|   |-- YYYY-MM-DD/            # Dated snapshot directories
|-- scripts/                   # Utility scripts
```

### Snapshots

For temporal analysis (tracking how work evolves), copy key files into `snapshots/YYYY-MM-DD/` at any point. Snapshots are read-only records. Comparing snapshots across dates shows how your analysis developed over time.

### File Naming Conventions

- `snake_case` for all filenames
- Prefix with category: `raw_`, `analysis_`, `deliverable_`, `script_`
- Version deliverables: `_v1`, `_v2`
- Date-stamp raw data: `raw_sample_technical_2026-03-26.md`

## Framework Files

This repo contains the reusable framework only. No project-specific data.

| File | Purpose |
|------|--------|
| `new-project.ps1` | Create a new Local Project (Windows) |
| `new-project.sh` | Create a new Local Project (macOS/Linux) |
| `setup.ps1` | Create a standalone workspace at any path (Windows) |
| `setup.sh` | Create a standalone workspace at any path (macOS/Linux) |
| `templates/` | Reusable templates for session state, pattern catalogs, evidence libraries, analysis frameworks |

## Customization

The default workspaces root is `C:\Dev\workspaces` (Windows) or `~/dev/workspaces` (macOS/Linux). Override it:

```powershell
.\new-project.ps1 -Name "my-project" -WorkspacesRoot "D:\Research\workspaces"
```

```bash
./new-project.sh my-project "Description" ~/research/workspaces
```

## Use Cases

- Multi-session research projects
- Long-running analytical work
- Iterative document building across conversations
- Any work where Claude needs to "remember" across sessions without losing conversation search access
- Collaborative studies requiring persistent evidence libraries and pattern catalogs

## Architecture Notes

The Filesystem MCP is the only required integration. Claude reads and writes directly to your local filesystem. No cloud storage, no API keys, no external dependencies. Your data stays on your machine.

The workspace is a directory convention plus a session state protocol plus a project registry. The value comes from the pattern, not from any particular technology.

## License

MIT License. See [LICENSE](LICENSE) for details.

## Author

Built by Barry Kramer -- fractional CAISO and Senior vCISO with 40+ years in IT and 30+ years in information security. This tool emerged from practical needs during multi-session AI-assisted analytical work and is published as a general-purpose framework for anyone doing sustained research or analysis with Claude.
