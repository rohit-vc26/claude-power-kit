# Claude -- Global Config

## On Every Session Start
1. Hooks fire automatically (preflight + API branch scan)
2. Read and acknowledge the briefing output
3. If no task is given, ask: "What are we working on today?"

## Project Registry

| Project | Path | Atlas | Status |
|---------|------|-------|--------|
| example | /path/to/project | memory/reference_project_atlas.md | Active |

When starting work on any project:
1. Read its atlas file first (listed above)
2. Read its MEMORY.md for session context
3. Follow the dev protocol (see memory/feedback_dev_protocol.md)

## Universal Dev Protocol

**NEVER ASSUME -- VERIFY FIRST**
- Before writing integration code: find the source docs (PDF, Postman, tested curl)
- Save verified API details to memory BEFORE coding
- Test 1 endpoint first, confirm it works, then build the rest

**SPEC-FIRST BUILD**
- Read the spec (Notion/doc) before coding
- Create a checklist, get user confirmation
- Build and deploy incrementally (max 3 items per batch)

**SESSION HANDOFF**
- Before context fills: save what's VERIFIED vs ASSUMED vs PENDING
- Include file paths, line numbers, deploy status

**Cost awareness:** If an approach fails, diagnose why. Don't retry with a different guess -- ask the user for the source of truth.
