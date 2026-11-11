---
name: self-improving-memory
description: >-
  Initialize and maintain a self-improving .claude/ memory system in any project — a lean
  CLAUDE.md index that @imports modular rule docs, an append-only lessons log that captures
  every bug/gotcha so it never repeats, and a Stop hook that auto-enforces lesson capture after
  code changes. Use this whenever the user wants to set up project memory, initialize or
  restructure .claude, stop CLAUDE.md from getting bloated, make the assistant self-improve /
  self-heal / learn from mistakes across sessions, or record a specific bug/fix/gotcha into
  durable memory. Also use to retrofit this structure onto a repo that already has a CLAUDE.md.
---

# Self-Improving Memory

## What this builds and why

A project's hard-won knowledge usually dies in one of two ways: it never gets written down, or it gets dumped into `CLAUDE.md` until that file is a 1,000-line wall nobody reads and every session pays for in tokens. This skill sets up a structure that fixes both:

- **`CLAUDE.md` becomes a lean index** — overview + a list of `@import` lines. It stays small.
- **Knowledge lives in `.claude/rules/*.md`**, split by domain, each `@import`ed so it's always in context without being read manually.
- **`.claude/rules/lessons.md` is an append-only memory** of bugs, gotchas, and wrong assumptions (newest on top). It loads every session, so the project gets *harder to break over time*.
- **A Stop hook enforces the loop**: if a session changed code but didn't record a lesson, it asks for one before stopping. Self-healing doesn't depend on the model remembering to do it.

The mechanism that prevents bloat: new learnings append to `lessons.md` (or a domain rule file), **never** to `CLAUDE.md`. The index only changes when a whole new domain file is added.

## Two modes

You're almost always in one of these. Figure out which from the request and the repo state.

1. **Initialize / retrofit** — "set up project memory", "initialize .claude", "make this self-improving", or the repo has no `.claude/rules/` yet. → Run the **Init workflow** below.
2. **Record a lesson** — "remember this", "log this gotcha", "we just fixed X, capture it", or the Stop hook fired. → Jump to **Recording a lesson**.

## Init workflow

Goal: leave the repo with a lean `CLAUDE.md` index, a populated `.claude/`, and an active Stop hook — idempotently (safe to re-run; never clobber existing lessons).

### 1. Survey the repo
Understand the project enough to write *useful* starter docs, not filler. Check: language/stack and package manifests, how to build/run/test/lint, top-level architecture (entry points, the few files that explain the whole), data model or core domain concepts, and any obvious footguns (env handling, multi-tenancy, money math, deploy quirks). If a `CLAUDE.md` already exists, read it — you'll be refactoring it, not discarding it.

### 2. Create the structure
Create these (use the bundled templates in `assets/`, substituting `{{PROJECT}}` and `{{DATE}}`):

```
.claude/
  README.md            ← from assets/readme.template.md
  hooks/
    lesson-guard.js    ← copy verbatim from this skill's scripts/lesson-guard.js
  rules/
    conventions.md     ← from assets/conventions.template.md, filled in for this project
    lessons.md         ← from assets/lessons.template.md (ONLY if it doesn't exist — never overwrite)
    <domain>.md        ← 1–4 files you write from the survey (see below)
  settings.json        ← register the Stop hook (see step 4)
```

**Domain rule files** are the real value. Derive them from the survey — typical splits:
- `architecture.md` — the big-picture structure that needs several files to understand. This is where most of an existing bloated `CLAUDE.md`'s body should move.
- `conventions.md` — workflow, build/test/deploy discipline, branch strategy (template covers the self-improvement loop; add project specifics).
- `data-model.md` / `domain.md` — core entities, invariants, status flows — when the domain is non-trivial.
- `gotchas.md` — known sharp edges that aren't yet "lessons" (env traps, platform quirks).

Write each file single-purpose and tight. Don't pad. A rule file should read like something you'd want loaded into every session.

### 3. Make CLAUDE.md a lean index
Create `CLAUDE.md` (or refactor the existing one) to: a short "what this is", the few commands that matter, and an **Imports** section. Move detailed prose *out* into the rule files. Target: the index itself is well under ~100 lines; depth lives in the imports.

```markdown
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is
<2–4 lines: what the project is, the deployables>

## Commands
<the handful of build/run/test commands that matter>

## Project memory (auto-loaded)
@.claude/rules/conventions.md
@.claude/rules/architecture.md
@.claude/rules/lessons.md
<one @import line per rule file>
```

`@`-imports are resolved by Claude Code relative to the file, so paths start at repo root. If a `CLAUDE.md` already had good content, preserve its facts — relocate them into the right rule file, then import. Don't lose information; move it.

### 4. Register and verify the hook
Copy `scripts/lesson-guard.js` to `.claude/hooks/lesson-guard.js`. Then wire it in `.claude/settings.json` (merge into existing `hooks` if the file already exists — don't blow away other settings):

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "node .claude/hooks/lesson-guard.js" }
        ]
      }
    ]
  }
}
```

The hook is Node (cross-platform; runs on Windows dev and Linux CI/VPS alike) and is silent unless code changed without a lesson being recorded. Confirm it parses and runs:

```bash
node .claude/hooks/lesson-guard.js   # prints nothing, or a JSON block decision; exit 0
```

If `node` isn't the right runtime for the project, keep the script but point the command at the available runtime — the logic only needs `git` and a JS engine.

### 5. Check that memory is committable
The whole point is a *shared* source of truth, so it must be trackable by git. Check `.gitignore` for rules that would hide it — a blanket `*.md` (ignores `CLAUDE.md` and every rule file) or an ignored `.claude/` are common traps. If found, tell the user and offer to un-ignore (negations like `!CLAUDE.md` and `!.claude/`, or `git add -f`). This also matters because the hook's git-status step won't see ignored code, though lesson detection uses mtime and is unaffected.

### 6. Report
Tell the user what was created, what moved out of `CLAUDE.md`, and the one rule they need to know: **learnings append to `lessons.md`, never to `CLAUDE.md`.**

## Recording a lesson

This is the day-to-day heartbeat. Triggered explicitly ("capture this") or by the Stop hook firing.

Append to `.claude/rules/lessons.md`, **newest on top**, under a date heading (`## YYYY-MM-DD`; reuse today's heading if present). Keep it append-only — never edit or delete past lessons; they're the record.

A good lesson is the takeaway, not the diary:

**Example — good:**
```
- **Never anchor a monthly window on a mutable date column.** The admin step
  overwrites `redeemdate=NOW()`, so a redeem created in month M but processed in
  M+1 fell out of M's count and restored a slot (over-redeem). Fix: stamp the
  immutable `transdate` on insert and scope on `COALESCE(transdate, redeemdate)`.
```

**Example — too weak (avoid):**
```
- Fixed a bug in the redeem code today.
```

The difference: the good one states the *rule* (don't key windows on mutable columns), the *mechanism* (admin overwrites the date), and the *fix* — so a future session avoids the whole class of bug. The weak one is a changelog entry that teaches nothing.

If a session changed code but there's genuinely no durable lesson (pure feature add, no surprise), append a single honest line under today's date saying so. That satisfies the hook and keeps the record truthful — don't invent a lesson to game the check.

## Keeping it lean over time

- Default destination for a new learning is `lessons.md`. Promote a recurring theme into a dedicated rule file only when it stops being a "gotcha" and becomes "how this domain works."
- When a rule file outgrows roughly a screen, split it and add an `@import`. One file, one concern.
- `CLAUDE.md` should change rarely — basically only when you add a new rule file (one new `@import` line) or a top-level command changes.

## Notes
- Idempotent: re-running Init must never overwrite `lessons.md` or drop existing rule content. Read before you write; merge, don't clobber.
- This is a *flexible* skill — adapt the rule-file split to the project. The non-negotiables are: lean index, `@import`ed modular docs, append-only lessons, and the enforcing hook.
