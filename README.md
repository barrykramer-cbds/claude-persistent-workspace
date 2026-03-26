# Claude Persistent Workspace

A local filesystem workspace pattern for Claude that provides persistent project state across conversation sessions without sacrificing access to conversation history search.

This tool creates **Local Projects** -- persistent workspaces on your machine managed through the Filesystem MCP. These are distinct from **Claude Projects** (Anthropic's built-in feature), which provide persistent context but isolate your conversation from history search tools. The two approaches are complementary.

## The Problem

Anthropic's Claude Projects give you persistent context across sessions. The tradeoff: they isolate your conversation from general history search tools (`conversation_search` and `recent_chats`). For analytical work that needs both persistent state AND dynamic evidence gathering from past conversations, this is a forced choice that degrades output quality.

## The Solution

Local Project workspaces on your machine, accessed via the Filesystem MCP. Files written during one conversation persist on disk. Any future conversation can read them through the same MCP connection. Because you never enter a Claude Project boundary, your full conversation search access is preserved.

You get persistence AND search. No tradeoff.

## Understanding Token Economics

This section matters for everyone, especially users on plans with smaller context windows.

### How Claude Projects Handle Tokens

When you use Anthropic's built-in Claude Projects, every file in the project's knowledge base is injected into the context window at the start of every conversation. If you have 50 pages of reference material in a Claude Project, those tokens are consumed the moment the conversation opens, whether you need that material or not. On a plan with a smaller context window, this can consume a significant percentage of your available space before you type a single message.

### How Local Projects Handle Tokens

Local Projects have zero token cost when you're not using them. The files sit on your disk. The Filesystem MCP connection itself consumes no context window space. Your workspaces could contain gigabytes of data and it would have no effect on any conversation that doesn't explicitly read from them.

When you do start a session with a Local Project, the token cost is minimal and controlled:

1. Claude reads `.session_state.md` (typically under 1KB)
2. Claude reads `context/manifest.md` (a small index file)
3. During the session, Claude loads specific files only when needed

You pay tokens only for what you actually use in that session. A session that touches 2 of your 10 reference documents only loads those 2.

### The context/ Directory and Selective Loading

The `context/` directory is your project's persistent knowledge base, similar to dropping files into a Claude Project. The difference is how they're consumed.

In a Claude Project, everything loads at once. In a Local Project, Claude reads the `context/manifest.md` index first. This small file describes what's available. Claude then loads specific documents on demand during the session.

This means:
- A 200-page reference document doesn't cost tokens until a question requires it
- Sessions focused on one aspect of your project don't waste space on unrelated material
- Long analytical sessions preserve more context window for actual conversation history and reasoning

You can always tell Claude to "load everything in context" at the start of a session if you know you'll need it all. The manifest gives Claude the intelligence to be selective by default.

### Practical Impact

On a plan with a smaller context window, the difference is significant. A Claude Project with 5 reference documents might consume 30-40% of your context window before the conversation begins. The same material in a Local Project's `context/` directory costs nothing until requested, and even then only the specific document needed gets loaded.

For users on larger plans, the benefit shifts from capacity to quality. More context window available for conversation means Claude can maintain longer analytical threads without earlier content being pushed out of context.

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

This creates a fully scaffolded workspace under the workspaces root directory and registers it in the project registry.

### 3. Add Project Knowledge

Drop reference files into the `context/` directory of your project. Update `context/manifest.md` to describe them:

```markdown
| File | Size | Description |
|------|------|-------------|
| voice_profile_v2.md | 12KB | Writing style reference and voice characteristics |
| project_spec.md | 8KB | Original project specification and requirements |
| prior_analysis.md | 25KB | Results from Phase 1 analysis |
```

Claude reads this manifest at session start and loads files selectively based on what the session needs.

### 4. Start Working

Open a Claude conversation and say:

> "Read C:\Dev\workspaces\my-research\.session_state.md and let's get started."

Or to see all your projects:

> "Show me my Local Projects."

## How It Works

### Local Projects vs Claude Projects

| | Local Projects (this tool) | Claude Projects (Anthropic) |
|---|---|---|
| Persistence | Files on your local disk | Anthropic's project context |
| Conversation search | Full access preserved | Isolated from history |
| Token cost at idle | Zero | N/A (not in conversation) |
| Token cost at session start | Minimal (state + manifest) | Full knowledge base loaded |
| Context loading | Selective, on-demand | All files, every session |
| Data location | Your machine only | Anthropic's servers |
| Setup | Filesystem MCP required | Built into Claude |
| Best for | Multi-session research needing history access and token efficiency | Self-contained work within a project boundary |

Use Claude Projects for self-contained work. Use Local Projects for work that spans your full conversation history or where token efficiency matters.

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
2. **Load context index** -- Claude reads `context/manifest.md` to know what reference material is available
3. **During session** -- Claude reads and writes files as needed, loading context documents on demand
4. **End of session** -- Claude updates `.session_state.md` with what was accomplished, what changed, and what the next session should prioritize

### Project Directory Structure

Each Local Project gets this scaffold:

```
project-name/
|-- .session_state.md          # Session handoff state (read first every session)
|-- context/                   # Project knowledge base (like Claude Project files)
|   |-- manifest.md            # Index of available context files
|   |-- (your files here)      # Drop reference docs, profiles, specs here
|-- raw/                       # Primary source data
|   |-- samples/               # Conversation excerpts, writing samples, evidence
|   |-- external/              # Third-party data, research, reference material
|   |-- uploads/               # Files to be processed and filed
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

### The context/ Directory

The `context/` directory is your project's persistent knowledge base. It functions like the file uploads in Anthropic's Claude Projects, with one key difference: files are loaded selectively instead of all at once.

Put anything here that Claude should have available across sessions: style guides, project specs, profile documents, prior analysis results, reference material. Update `context/manifest.md` to describe each file.

At session start, Claude reads the manifest (small, fast) and then loads individual files on demand based on what the session's work requires. This preserves context window space for the actual conversation.

The distinction from `raw/uploads/`:
- `context/` = always-available project knowledge. Claude reads the manifest every session.
- `raw/uploads/` = data to be processed. One-time inputs that get filed into analysis directories.

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
| `templates/` | Reusable templates for session state, context manifest, pattern catalogs, evidence libraries, analysis frameworks |

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
- Token-constrained environments where selective loading beats full knowledge base injection

## Architecture Notes

The Filesystem MCP is the only required integration. Claude reads and writes directly to your local filesystem. No cloud storage, no API keys, no external dependencies. Your data stays on your machine.

The workspace is a directory convention plus a session state protocol plus a project registry plus a selective context loading pattern. The value comes from the pattern, not from any particular technology.

## License

MIT License. See [LICENSE](LICENSE) for details.

## Author

Built by Barry Kramer -- fractional CAISO and Senior vCISO with 40+ years in IT and 30+ years in information security. This tool emerged from practical needs during multi-session AI-assisted analytical work and is published as a general-purpose framework for anyone doing sustained research or analysis with Claude.
