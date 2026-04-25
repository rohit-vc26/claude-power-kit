---
name: superpowers-debugging
description: "Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes. Enforces systematic root-cause investigation instead of random fix attempts. Trigger whenever you see errors, test failures, bugs, performance issues, or build failures."
---

# Systematic Debugging

## Overview

Random fixes waste time and create new bugs. Quick patches mask underlying issues.

**Core principle:** ALWAYS find root cause before attempting fixes. Symptom fixes are failure.

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

If you haven't completed Phase 1, you cannot propose fixes.

## The Four Phases

### Phase 1: Root Cause Investigation

**BEFORE attempting ANY fix:**

1. **Read Error Messages Carefully** - Don't skip past errors. They often contain the exact solution. Read stack traces completely.

2. **Reproduce Consistently** - Can you trigger it reliably? What are the exact steps?

3. **Check Recent Changes** - Git diff, recent commits, new dependencies, config changes, environmental differences

4. **Gather Evidence in Multi-Component Systems** - For each component boundary: log what enters, log what exits, verify config propagation. Run once to gather evidence showing WHERE it breaks.

5. **Trace Data Flow** - Where does bad value originate? What called this with bad value? Keep tracing up until you find the source. Fix at source, not at symptom.

### Phase 2: Pattern Analysis

1. **Find Working Examples** - Locate similar working code in same codebase
2. **Compare Against References** - Read reference implementation COMPLETELY, don't skim
3. **Identify Differences** - List every difference, however small
4. **Understand Dependencies** - What settings, config, environment does this need?

### Phase 3: Hypothesis and Testing

1. **Form Single Hypothesis** - "I think X is the root cause because Y"
2. **Test Minimally** - SMALLEST possible change. One variable at a time.
3. **Verify Before Continuing** - Didn't work? Form NEW hypothesis. DON'T add more fixes on top.

### Phase 4: Implementation

1. **Create Failing Test Case** - Simplest possible reproduction
2. **Implement Single Fix** - ONE change at a time. No "while I'm here" improvements.
3. **Verify Fix** - Test passes? No other tests broken?
4. **If 3+ Fixes Failed: Question Architecture** - Each fix reveals new problem in different place = architectural problem. Discuss with your human partner before attempting more fixes.

## Red Flags - STOP and Follow Process

If you catch yourself thinking:
- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "It's probably X, let me fix that"
- "I don't fully understand but this might work"
- Proposing solutions before tracing data flow

**ALL of these mean: STOP. Return to Phase 1.**

## Quick Reference

| Phase | Key Activities | Success Criteria |
|-------|---------------|------------------|
| **1. Root Cause** | Read errors, reproduce, check changes, gather evidence | Understand WHAT and WHY |
| **2. Pattern** | Find working examples, compare | Identify differences |
| **3. Hypothesis** | Form theory, test minimally | Confirmed or new hypothesis |
| **4. Implementation** | Create test, fix, verify | Bug resolved, tests pass |

## Real-World Impact

- Systematic approach: 15-30 minutes to fix
- Random fixes approach: 2-3 hours of thrashing
- First-time fix rate: 95% vs 40%
- New bugs introduced: Near zero vs common
