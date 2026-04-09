# Claude Power Kit

Dev protocol enforcement system for Claude Code. Prevents spec drift, wrong API assumptions, and wasted tokens across sessions.

## What It Does

Every time you start a Claude Code session, two hooks fire automatically:

1. **Preflight Check** -- reminds Claude to read the project atlas and dev protocol before writing any code
2. **API Branch Scan** -- shows all known APIs across projects, flags any new API client files it discovers in your codebase

## What's Included

```
claude-power-kit/
  install.sh                    # One-command installer
  uninstall.sh                  # Clean removal
  hooks/
    preflight.sh                # Session start: atlas + protocol check
    api_scan_hook.sh            # Session start: API registry status
  api-branch/
    scanner.py                  # API auto-discovery engine
    registry.template.json      # Empty registry template
  templates/
    CLAUDE.md                   # Global Claude config template
  memory-templates/
    MEMORY.md                   # Memory index template
    feedback_dev_protocol.md    # 5 dev rules to prevent drift
    reference_project_atlas.template.md  # Project architecture template
```

## Install

```bash
git clone <this-repo>
cd claude-power-kit
bash install.sh
```

The installer:
- Auto-detects your Python3 path
- Creates `~/.claude/hooks/` and `~/.claude/api-branch/`
- Merges hooks into your existing `settings.json` (doesn't overwrite)
- Backs up settings before modifying

## Post-Install Setup

### 1. Register your projects

```bash
python3 ~/.claude/api-branch/scanner.py --add-project myapp /path/to/myapp
```

### 2. Run first scan

```bash
python3 ~/.claude/api-branch/scanner.py --scan --tree
```

### 3. Set up project memory

```bash
# Create project memory directory
mkdir -p ~/.claude/projects/-path-to-myapp/memory/

# Copy templates
cp memory-templates/*.md ~/.claude/projects/-path-to-myapp/memory/

# Edit the atlas with your project details
```

Note: Claude Code encodes project paths by replacing `/` with `-` and prepending `-`. 
Example: `/Users/john/projects/myapp` becomes `-Users-john-projects-myapp`.

### 4. Add API details to registry

When you discover/verify API integrations, add them to `~/.claude/api-branch/registry.json`. Each API entry should include:

```json
{
  "name": "Service Name",
  "base_url": "https://api.example.com/v1",
  "auth": {
    "method": "header|query_param|body|oauth2|sdk",
    "key": "the auth key name",
    "note": "important auth details"
  },
  "client_file": "app/services/example_client.py",
  "status": "active",
  "endpoints": [
    {"method": "GET", "path": "/resource", "name": "List resources", "tested": true}
  ],
  "gotchas": [
    "Important things to remember"
  ]
}
```

## Scanner Commands

```bash
python3 ~/.claude/api-branch/scanner.py                          # Status
python3 ~/.claude/api-branch/scanner.py --scan                   # Full scan
python3 ~/.claude/api-branch/scanner.py --scan --tree            # Scan + readable tree
python3 ~/.claude/api-branch/scanner.py --scan --quiet           # Hook mode (minimal)
python3 ~/.claude/api-branch/scanner.py --diff                   # Changes only
python3 ~/.claude/api-branch/scanner.py --add-project NAME PATH  # Register project
python3 ~/.claude/api-branch/scanner.py --tree                   # Generate tree view
```

## How the Scanner Works

- Reads Python files looking for: base URL constants, auth patterns, `*Client`/`*Service` classes, SDK imports
- Reads JS/TS files looking for: `fetch()` URLs, API base constants
- Skips: test files, venv, node_modules, build dirs
- Filters out: localhost, the project's own domain
- **Never makes HTTP calls** -- read-only code analysis
- **Never silently fails** -- all errors surface in output

## Uninstall

```bash
bash uninstall.sh
```

Removes hooks, scanner, and registry. Project memory files are left untouched.

## The Dev Protocol (Why This Exists)

Five rules learned from expensive mistakes:

1. **Never assume APIs** -- get the official docs, verify with curl, then code
2. **Spec-first build** -- read the spec, make a checklist, get confirmation
3. **Session handoff** -- save verified/assumed/pending state before context fills
4. **One integration at a time** -- don't build multiple API clients in parallel
5. **Cost-aware debugging** -- diagnose failures, don't guess-and-retry
