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

## Response Style Rules (anti-drift)

These are hard rules. Drift is real -- the dev_rules_guard PreToolUse hook reminds you when you slip, but you should not need it.

- **No em dashes.** Use hyphen (-) only. Em dash (--) is also banned. The character `—` is banned in all output (chat replies, code, comments, file content).
- **Default answer length: under 6 lines.** Long responses only when the user asks for depth (review, plan, audit). Never pad with summaries-of-summaries or "TLDR" sections.
- **No decorative tables or headers** unless the structure genuinely helps. One pass-through paragraph beats a 5-row table for most answers.
- **Before editing any function/class:** run `gitnexus_impact <symbol>` and surface d=1 risk. No exceptions for "small" edits.
- **Before any deploy:** run `gitnexus_detect_changes` and confirm scope matches expectation.
- **Max 3 files per deploy batch.** If a feature touches more, split into staged rollouts. Coordinated multi-file releases require explicit user approval.
- **Read models/schemas end-to-end** before writing code that uses them. Do not guess column names.
- **Verify in production cleanly** before declaring success. One log line that says "OK" is worth more than three messages claiming "should work".

## Behaviour When You Slip
If you catch yourself drifting (long answer, em dash, skipped impact analysis), say so directly in the next message. Do not paper over it. The user values calibrated honesty more than polished prose.
