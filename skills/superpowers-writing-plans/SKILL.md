---
name: superpowers-writing-plans
description: "Use when you have a spec or requirements for a multi-step task, before touching code. Creates detailed implementation plans with bite-sized tasks. Trigger whenever a feature needs to be broken down into steps, or when planning implementation of any non-trivial change."
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for the codebase. Document everything they need to know: which files to touch, code, testing, how to test it. Give them the whole plan as bite-sized tasks.

DRY. YAGNI. TDD. Frequent commits.

## Scope Check

If the spec covers multiple independent subsystems, suggest breaking this into separate plans - one per subsystem. Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for.

- Design units with clear boundaries and well-defined interfaces
- Prefer smaller, focused files over large ones that do too much
- Files that change together should live together
- In existing codebases, follow established patterns

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

Every plan should start with:
- **Goal:** One sentence describing what this builds
- **Architecture:** 2-3 sentences about approach
- **Tech Stack:** Key technologies/libraries

## Task Structure

```markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py`
- Test: `tests/exact/path/to/test.py`

- [ ] **Step 1: Write the failing test**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Write minimal implementation**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit**
```

## Remember

- Exact file paths always
- Complete code in plan (not "add validation")
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits
