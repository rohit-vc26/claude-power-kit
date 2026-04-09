---
name: Dev Protocol
description: 5 rules to prevent spec drift, wasted tokens, and wrong API assumptions
type: feedback
---

## Rule 1: NEVER ASSUME APIs -- VERIFY FIRST

Before writing ANY integration code:
1. Find the official docs (PDF, Postman collection, tested curl)
2. Save verified details to memory (base URL, auth method, endpoints)
3. Test 1 endpoint with curl, confirm it works
4. THEN build the client

**Why:** We rebuilt the WarmupIP client 3x because of wrong URL and auth assumptions. Each rebuild cost real tokens and time.

**How to apply:** If you don't have the official docs, ASK the user for them. Never guess a base URL or auth method.

## Rule 2: SPEC-FIRST BUILD

1. Read the spec/design doc BEFORE coding
2. Create a numbered checklist from the spec
3. Get user confirmation on the checklist
4. Build max 3 items per deploy batch

**Why:** Building without reading the spec leads to 40% correct implementations that need full rebuilds.

## Rule 3: SESSION HANDOFF

Before context fills up, save a snapshot:
- What's VERIFIED (tested, deployed, confirmed working)
- What's ASSUMED (built but not tested)
- What's PENDING (not started, blocked)
- File paths + line numbers for all changes

**Why:** New sessions start blank. Without handoff, work gets repeated or contradicted.

## Rule 4: ONE INTEGRATION AT A TIME

When connecting to a new API:
1. Get the docs
2. Save to API branch registry
3. Build the client
4. Test 1 endpoint
5. Confirm with user
6. Then build the rest

Never build multiple integrations in parallel.

## Rule 5: COST-AWARE DEBUGGING

If an approach fails:
- Read the error message carefully
- Check your assumptions against the source docs
- If you don't have source docs, ASK for them
- Never retry with a different guess -- diagnose first

**Why:** Each wrong guess costs tokens and erodes trust.
