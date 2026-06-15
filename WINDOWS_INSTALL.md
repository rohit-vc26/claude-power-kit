# Windows Installation Guide — Claude Power Kit

The install script is a bash script. Running it in **Windows PowerShell will not work**. You need **Git Bash** (or WSL). This guide walks you through the full setup.

---

## Why PowerShell Fails

| What you tried | Why it breaks |
|---|---|
| `bash ~/claude-power-kit/install.sh` | PowerShell doesn't have `bash` built-in |
| `cd ~/neural-command-system && npm run dev` | `&&` is not valid in PowerShell 5.x |

The fix is simple: **use Git Bash for everything below.**

---

## Step 1 — Install Prerequisites

Open **Windows PowerShell** (just this once) and run each line:

```powershell
winget install Git.Git
winget install OpenJS.NodeJS.LTS
winget install Python.Python.3.11
```

After installation, **close PowerShell** — you will not use it again.

> If `winget` is not available, download installers manually:
> - Git for Windows: https://git-scm.com/download/win  
> - Node.js LTS: https://nodejs.org  
> - Python 3.11+: https://python.org/downloads

---

## Step 2 — Open Git Bash

Git Bash is installed with "Git for Windows". Open it one of these ways:

- **Right-click** any folder → **Git Bash Here**
- **Start Menu** → search `Git Bash` → open it
- In Windows Explorer, navigate to `C:\Users\<YourName>` and right-click → Git Bash Here

You'll see a terminal with a `$` prompt instead of `PS >`. That's Git Bash.

---

## Step 3 — Clone and Install

Run these commands **inside Git Bash** (not PowerShell):

```bash
git clone https://github.com/rohit-vc26/claude-power-kit ~/claude-power-kit
cd ~/claude-power-kit
bash install.sh
```

The installer auto-detects Windows (Git Bash / MINGW) and adjusts accordingly.

---

## Step 4 — Start the NCS Dashboard

After install completes, start the NCS dashboard from **Git Bash**:

```bash
cd ~/neural-command-system
npm run dev
```

Then open your browser at: `http://localhost:3777`

> **PowerShell users:** if you want to use PowerShell, run the two commands separately — `&&` doesn't work in PowerShell 5.x:
> ```powershell
> cd ~\neural-command-system
> npm run dev
> ```

---

## Step 5 — Open Claude Code

```bash
claude
```

Or launch from your project folder:

```bash
cd ~/your-project
claude
```

Type `/terra` in any Claude Code session to activate the full workflow.

---

## Common Issues

### `bash: command not found` in PowerShell
You're in PowerShell, not Git Bash. Open Git Bash from Start Menu and re-run.

### `'&&' is not a valid statement separator`
PowerShell 5.x doesn't support `&&`. Either:
- Use Git Bash (recommended)
- Upgrade to PowerShell 7: `winget install Microsoft.PowerShell`
- Run the commands one at a time in PowerShell

### `python3: command not found` in Git Bash
Git Bash on Windows uses `python` not `python3`. Run this once in Git Bash to create an alias:
```bash
echo "alias python3=python" >> ~/.bashrc && source ~/.bashrc
```

### `node: command not found` in Git Bash after installing Node
Close and reopen Git Bash — it needs a fresh session to pick up the new PATH.

### NCS clone fails (network/proxy error)
If your corporate network blocks GitHub, clone manually over HTTPS:
```bash
git clone https://github.com/rohit-vc26/IQ.git ~/neural-command-system
cd ~/neural-command-system
npm install
```

### Claude Code not found after `npm install -g @anthropic-ai/claude-code`
Close and reopen Git Bash, then try `claude --version`. If still missing:
```bash
npm list -g @anthropic-ai/claude-code
# Check the path shown and add it to your PATH in ~/.bashrc
```

---

## WSL Alternative (Advanced)

If you prefer a full Linux environment on Windows:

```powershell
# In PowerShell (admin)
wsl --install
```

After WSL installs and you set up Ubuntu, follow the standard Linux install:

```bash
git clone https://github.com/rohit-vc26/claude-power-kit ~/claude-power-kit
cd ~/claude-power-kit
bash install.sh
```

WSL gives you native `bash`, `python3`, and full Linux PATH — no quirks.

---

## Quick Reference: PowerShell vs Git Bash

| Task | PowerShell ❌ | Git Bash ✓ |
|---|---|---|
| Run install script | `bash install.sh` (fails) | `bash install.sh` |
| Chain commands | `cmd1 && cmd2` (fails in 5.x) | `cmd1 && cmd2` |
| Home directory `~` | `C:\Users\name` | `/c/Users/name` |
| Python | `python` | `python` or `python3` |
| Background processes | Different syntax | Unix-standard |
