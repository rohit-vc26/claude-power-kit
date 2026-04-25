# Claude Power Kit v2

Full Claude Code agent setup — hooks, skills, NCS dashboard, GitNexus knowledge graph.
One `git clone + bash install.sh` gives you the complete dev workflow on any machine.

**Works on:** macOS · Ubuntu · Linux

---

## What You Get

### Layer 0 — Session Boot (fires on every session start)

```
1. gstack-update-check    → skill update notifications
2. GitNexus freshness     → index FRESH ✓ or STALE ⚠ before work begins
3. NCS briefing           → agent roster + live task count
4. live_session_tracker   → writes STARTING state to Karma
5. preflight              → atlas / protocol / memory check per project
6. api_scan_hook          → API registry scan across all projects
```

### Layer 1 — Slash Commands

All commands available in the Claude Code slash-command dropdown (`/`):

| Command | Agent | Role |
|---------|-------|------|
| `/terra` | Terra | CEO — reads situation, delegates to right agent |
| `/review` | Ignis | Code review |
| `/investigate` | Ignis | Debugging & root cause |
| `/plan-eng-review` | Ignis | Engineering plan review |
| `/ops-manager` | Atlas | COO / Operations |
| `/digital-marketing-pro` | Hermes | CMO / Growth |
| `/design-consultation` | Aqua | Design direction |
| `/design-review` | Aqua | Design quality check |
| `/design-shotgun` | Aqua | Fast design options |
| `/qa` | Zephyr | QA testing |
| `/canary` | Zephyr | Smoke tests |
| `/ship` | Solaris | Deploy + release |
| `/land-and-deploy` | Solaris | Full deploy flow |
| `/cso` | Ferrum | Security officer |
| `/careful` `/guard` | Obsidian | Safety + blast radius |
| `/freeze` `/unfreeze` | Obsidian | Lock/unlock deploys |
| `/learn` | Mnemora | Save learnings to memory |
| `/browse` | Spectra | Browser & recon |
| `/ui-ux-pro-max` | Aqua | Full UI/UX rules + auto-reads DESIGN.md |
| `/senior-dev-mode` | Ignis | Deep engineering mode |
| `/security-guardian` | Ferrum | Security audit |
| `/fullstack-developer` | Aqua | Full-stack build |
| `/superpowers-debugging` | Ignis | Advanced debugging |
| `/superpowers-tdd` | Zephyr | TDD workflow |
| `/gitnexus-*` (7 skills) | — | Code graph: explore/debug/refactor/impact/pr-review |
| + 15 more... | — | checkpoint, benchmark, autoplan, retro, health, ... |

### Layer 2 — Active Work (every tool call)

```
PreToolUse  (Grep/Glob/Bash) → GitNexus enriches searches with graph context
PostToolUse (Bash)           → GitNexus detects git mutations → flags stale index
```

### Layer 3 — Session Close

```
Stop      → live_session_tracker writes STOPPED
SessionEnd → live_session_tracker writes ENDED
SessionEnd → session_title_generator auto-titles from git commits (or Haiku LLM)
```

### Layer 4 — NCS Dashboard (always-on background)

```
http://localhost:3777 — Next.js agent dashboard
  agents.json    → live agent status (Terra/Ignis/Atlas/...)
  todos.json     → task queue
  activity.json  → session history
  /api/tasks     → POST endpoint for /terra to log delegated tasks
```

---

## Agent Roster

12-agent org chart — Terra orchestrates, all others execute:

```
Tier 0:  Terra    — CEO/Strategy (earth)
Tier 1:  Ignis    — Engineering Lead
         Hermes   — CMO/Growth
         Atlas    — COO/Operations
Tier 2:  Aqua     — Designer
         Zephyr   — QA Engineer
         Solaris  — Release Manager
         Aether   — DevEx Lead
         Mnemora  — Memory & Planning
         Spectra  — Browser & Recon
Tier 3:  Ferrum   — Security Officer
         Obsidian — Safety Guardian
```

---

## Install

```bash
git clone https://github.com/rohit-vc26/claude-power-kit
cd claude-power-kit
bash install.sh
```

The installer:

1. Detects platform (macOS/Ubuntu/Linux)
2. Installs Node.js via nvm if missing
3. Installs bun (required by gstack)
4. Installs Claude Code CLI if missing
5. Clones gstack → all slash commands available
6. Installs custom skills (ui-ux-pro-max, ops-manager, senior-dev-mode, ...)
7. Installs GitNexus globally + runs `gitnexus setup`
8. Clones NCS dashboard → `~/neural-command-system/`
9. Copies all hooks → `~/.claude/hooks/`
10. Merges all 6 hook events into `~/.claude/settings.json`

---

## Post-Install

### 1. Index your project with GitNexus

```bash
cd /your/project
npx gitnexus analyze
```

### 2. Register APIs for scanning

```bash
python3 ~/.claude/api-branch/scanner.py --add-project myproject /path/to/project
python3 ~/.claude/api-branch/scanner.py --scan --tree
```

### 3. Start NCS dashboard

```bash
cd ~/neural-command-system && npm run dev
# Open: http://localhost:3777
```

### 4. Add project memory templates

```bash
cp memory-templates/*.md ~/.claude/projects/<your-project>/memory/
```

---

## Repo Structure

```
claude-power-kit/
├── install.sh                         # One-command installer
├── uninstall.sh                       # Clean removal
├── hooks/
│   ├── preflight.sh                   # SessionStart: atlas/protocol/memory check
│   ├── api_scan_hook.sh               # SessionStart: API registry scan
│   ├── ncs_briefing.sh                # SessionStart: NCS agent roster (dynamic node)
│   ├── live_session_tracker.py        # SessionStart/UserPromptSubmit/Notification/Stop/SessionEnd
│   ├── session_title_generator.py     # SessionEnd: auto-title from git/LLM
│   └── gitnexus/
│       └── gitnexus-hook.cjs          # SessionStart/PreToolUse/PostToolUse: graph context
├── api-branch/
│   ├── scanner.py                     # API auto-discovery engine
│   └── registry.template.json        # Empty registry template
├── skills/                            # Custom skills not in gstack
│   ├── ui-ux-pro-max/                 # UI/UX rules + DESIGN.md reader (v2)
│   ├── ops-manager/                   # Atlas: COO operations skill
│   ├── digital-marketing-pro/         # Hermes: CMO/growth skill
│   ├── senior-dev-mode/               # Ignis: deep engineering
│   ├── security-guardian/             # Ferrum: security audit
│   ├── fullstack-developer/           # Aqua: full-stack build
│   ├── superpowers-debugging/         # Advanced debugging
│   ├── superpowers-tdd/               # TDD workflow
│   ├── superpowers-brainstorming/     # Ideation
│   └── superpowers-writing-plans/     # Planning docs
├── templates/
│   ├── CLAUDE.md                      # Global Claude config template
│   └── settings.json.template         # Full hooks config (all 6 events)
└── memory-templates/
    ├── MEMORY.md                      # Memory index template
    ├── feedback_dev_protocol.md       # 5 dev rules to prevent drift
    └── reference_project_atlas.template.md
```

---

## Ubuntu Notes

All hooks use `python3` and `node` via PATH — no hardcoded macOS paths.
The installer auto-detects or installs Node.js via nvm on Ubuntu.
NCS dashboard runs identically on Ubuntu (Next.js).

---

## Hook Event Map

| Event | What fires |
|-------|------------|
| `SessionStart` | gstack check → gitnexus freshness → NCS briefing → tracker STARTING → preflight → api scan |
| `UserPromptSubmit` | tracker → LIVE |
| `Notification` | tracker → WAITING or STALE |
| `PreToolUse` | gitnexus enriches Grep/Glob/Bash with graph context |
| `PostToolUse` | gitnexus detects stale index after git mutations |
| `Stop` | tracker → STOPPED |
| `SessionEnd` | tracker → ENDED · session title generator |
