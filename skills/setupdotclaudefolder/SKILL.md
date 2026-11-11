---
name: setupdotclaudefolder
description: >-
  One-command .claude bootstrap for any project — replaces /init and /self-improving-memory.
  Composes three layers: (1) the dotclaude kit (github.com/poshan0126/dotclaude) — evidence-based
  scan/interview/install of rules, safety hooks, agents, skills; (2) the self-improving-memory
  loop — lean CLAUDE.md index, @imported rule files, append-only lessons.md, Stop hook that
  enforces lesson capture; (3) the user's NON-NEGOTIABLE idempotency/concurrency/security rules,
  installed verbatim into every project, plus the no-tracked-env-file and engineering-standards
  (clean/efficient/company-grade code) rules. Use whenever the user starts a new project, says
  "set up .claude", "/setupdotclaudefolder", or wants project memory initialized/retrofitted.
argument-hint: "[optional focus area, e.g. 'frontend' or 'backend']"
---

# setupdotclaudefolder

One governing principle inherited from dotclaude: **install nothing without evidence and
consent** — except Layers 3, 3b and 3c below, which the user has declared unconditional.

## Layers (apply in order)

### Layer 1 — dotclaude kit (scan → interview → plan → install)

Source of truth: https://github.com/poshan0126/dotclaude. Get the template:

```bash
# use the plugin if installed ($CLAUDE_PLUGIN_ROOT), else shallow-clone to a temp dir:
git clone --depth 1 https://github.com/poshan0126/dotclaude "$TMP/dotclaude"
```

Then follow the repo's own `skills/setupdotclaude/SKILL.md` flow exactly (it is the
authority for this layer — read it from the clone and execute its Phases 1–5):
deep read-only scan → AskUserQuestion interview (2 rounds: confirm reality; size =
Minimal/Standard/Full) → plan table (Install? | Evidence | Cost class) → approved install
(per-file copies from `template/`, customized `paths:`, settings.json wiring only installed
hooks, safety hooks default-on) → verify (CLAUDE.md ≤50 non-blank lines, always-loaded
token estimate, fingerprint).

### Layer 2 — self-improving-memory loop

Follow `~/.claude/skills/self-improving-memory/SKILL.md` Init workflow, merged with Layer 1
output (idempotent — never clobber what Layer 1 wrote):

- `CLAUDE.md` stays a **lean index**: what-this-is, commands, then `@.claude/rules/*.md`
  imports. Depth lives in the rule files, never inline.
- `.claude/rules/lessons.md` — append-only, newest-on-top; create only if absent.
- Stop hook `lesson-guard` (from the self-improving-memory skill's `scripts/lesson-guard.js`)
  wired into `.claude/settings.json` `hooks.Stop`, merged with dotclaude's hooks — do not
  overwrite the hooks array, append.
- The rule: **learnings append to lessons.md, never to CLAUDE.md.**

### Layer 3 — NON-NEGOTIABLES (unconditional, no interview question)

Copy this skill's `assets/nonnegotiables.template.md` verbatim to
`.claude/rules/idempotency-concurrency.md` and add its `@import` line to `CLAUDE.md`.
This installs in EVERY project regardless of size answer — it is the user's standing
directive (double-submit guards, duplicate-safe endpoints, double-fire tests, fail-closed
validation, boundary validation, no secrets/PII in logs, server-side authz, outbox for
side effects). If the project already has the file, diff and update to the newer template,
preserving any project-specific additions below the template body.

### Layer 3b — NO ENV FILE IS EVER TRACKED (unconditional)

Standing directive. Install in every project, no interview question.

**Every file whose name begins with `.env` is gitignored. No exceptions, and
that explicitly includes `.env.example`, `.env.sample`, `.env.template`, and
any other "safe placeholder" variant.**

The usual argument for committing `.env.example` is that it holds names, not
values. In practice it drifts: someone adds a default, a local dev password, a
sandbox key, or a comment quoting a real credential — and it is now a published
secret in a file everyone had agreed was harmless. That is not hypothetical.
A project doing exactly this shipped a seed password inside `.env.example`, in
a public repo, in a file whose own comment said "never use this value in
production" — and production was then seeded with it, leaving the admin account
open to anyone who read the repo.

The variable names still need documenting. Put them in the deploy guide
(`docs/DEPLOY-*.md`) or the README, in prose, where a reader is not tempted to
paste a working value next to the name.

**Setup steps:**

1. Ensure `.gitignore` contains a `.env*` line — the glob, not a list of
   specific filenames. A list always misses the next variant someone invents.
2. Run `git ls-files | grep -E '(^|/)\.env'`. Any hit is a live finding, not a
   style issue. Remove it with `git rm --cached`, and tell the user which
   values in it must be treated as compromised and rotated.
3. Verify with `git check-ignore -v .env .env.example` before reporting done.
4. State in the final report whether any env file was ever tracked, and if so,
   which secrets need rotating.

**When an env file was already committed:** rotation comes first, always.
Rewriting history with `git filter-repo` reduces future exposure but does not
un-publish anything — clones, forks, and provider caches may retain it. Never
present a history rewrite as remediation on its own; the credential is burned
the moment it is pushed, and only rotating it makes the system safe again.

### Layer 3c — ENGINEERING STANDARDS: write it like company code (unconditional)

Standing directive. Install in every project, no interview question.

Copy this skill's `assets/engineering-standards.template.md` verbatim to
`.claude/rules/engineering-standards.md` and add its `@import` line to `CLAUDE.md`.

The principle: **the bar is not "the code runs" — the bar is that a future developer who has
never met the author can read it, debug it, change it, and scale it.** Code is written once and
maintained for years; optimize for the reader, not the writer.

The rule file covers three things the user has declared non-negotiable:

1. **CLEAN** — readable, changeable, maintainable. Not "short", not "nicely formatted". The four
   tests: will another dev understand it, is it easy to debug, is it easy to change when the
   requirement changes, is there unnecessary duplication. Comments explain WHY, never WHAT.
2. **EFFICIENT** — does what is needed without wasting resources, across ALL axes: time, memory,
   database queries, network requests, CPU, scalability. No fetching 500,000 rows to show 10.
   No N+1 queries. Index what you filter on. Ask what happens at 100x.
3. **AI-GENERATED CODE IS THE HIGHEST-RISK CODE IN THE REPO** — it can look clean while being
   wrong, and it is the code most likely to be merged unread. Looking clean and being correct are
   unrelated properties. Every generated block gets reviewed for readability, maintainability,
   performance, security, unnecessary complexity, and scalability — and for whether the APIs and
   fields it used actually exist, rather than being plausible guesses. "It works" is the start of
   review, not the end.

If the project already has the file, diff and update to the newer template, preserving any
project-specific additions below the template body.

### Layer 3d — VPS SAFETY on shared production servers (unconditional)

Standing directive. Install in every project, no interview question: any project may end up on the
team's shared VPS, where one careless command takes other projects' apps down.

Copy this skill's `assets/vps-safety.template.md` verbatim to `.claude/rules/vps-safety.md` and add
its `@import` line to `CLAUDE.md`.

The principle: **evidence before claims, read-only before changes, and nothing that is not the
target may move.** Before giving any server command, read the local server notes, then send the
user one read-only context-gathering block written as if they are already logged in, and wait for
its output. Never claim a port, tool, resource or domain is available until fresh server output
shows it. Changes target processes by exact name, are fingerprinted before and after (all other PM2
apps and containers must be identical), avoid memory-heavy work on the shared box, come with a
rollback, and destructive commands need the user's explicit yes for that specific command.

If the project already has the file, diff and update to the newer template, preserving any
project-specific additions below the template body.

## Existing-project mode (retrofit)

Same three layers; Layer 1 runs as dotclaude's "Existing" gap-analysis mode (add missing +
justified, propose removals, never touch user-customized content without showing the diff).
An existing bloated CLAUDE.md gets refactored into the index+imports shape — move content
into rule files, lose nothing.

## Final report

- What was installed per layer (with evidence), what was skipped and why.
- CLAUDE.md line count + always-loaded token estimate.
- Confirm: lessons.md present, Stop hook runs (`node .claude/hooks/lesson-guard.js` exits 0),
  nonnegotiables rule imported, engineering-standards rule imported, vps-safety rule imported.
- Remind: memory must be git-trackable (check .gitignore traps like `*.md` or `.claude/`).
