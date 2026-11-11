# Engineering Conventions — Workflow & Self-Improvement

> Auto-loaded via `@import` into every session. These are the working rules for this repo.
> The point is not ceremony — it's that quality holds and knowledge compounds across sessions.

## Before you say "done" — EVERY task, no exceptions
This gate applies to every change, not just big ones. "Done" is a claim you must earn.
- **Falsify, don't justify.** Actively try to PROVE your own output WRONG before declaring it
  finished — don't look for reasons it works, look for the input that breaks it. Edge cases:
  empty/null, zero, negative, huge, concurrent, timezone/DST, rounding, legacy data, partial
  failure, re-run/idempotency. Only after you fail to break it is it done.
- **Hunt loopholes and bugs first.** Re-read the diff adversarially as if reviewing a stranger's
  code: off-by-one, wrong sign, unscoped query, silent catch, missing await, state mutation,
  assumption that a value is present. Find them before the user does.
- **Verify with real evidence.** Run it — build, test, the actual command — and quote the real
  output. Never claim "fixed" / "passing" / "works" from inspection alone or a "should work."
- **No silent scope creep or behavior change.** If you changed something beyond the ask, say so.

## The self-improvement loop
1. **Learn from every mistake.** When a bug, gotcha, or wrong assumption surfaces — especially
   after fixing one — append a concise entry to `.claude/rules/lessons.md` (newest on top, dated).
   A Stop hook (`.claude/hooks/lesson-guard.js`) backstops this: if a session changed code and
   didn't update `lessons.md`, it asks for the lesson before stopping.
2. **CLAUDE.md stays a lean index.** Durable knowledge lives in `.claude/rules/*` and is pulled
   in via `@import`. Don't grow CLAUDE.md — grow the rule files.
3. **Split a rule file when a domain gets heavy.** If one topic outgrows ~1 screen, give it its
   own `rules/<domain>.md` and add an `@import` line to CLAUDE.md. One file, one concern.

## Extra rigor for risky / shared / production code
- **Adversarial review of the diff** against its intended behavior — correctness, idempotency,
  security, and regressions. Fix findings before shipping. (Dispatch a reviewer subagent if the
  change is large.)
- **Cross-feature regression sweep.** Ask what *else* this could break. Enumerate shared
  touch-points (tables, services, shared utils, call sites) and verify each still holds —
  especially in generic/shared code paths where one edit fans out to many features.
- **Confirm hard-to-reverse or outward-facing actions before doing them** (deploys, migrations,
  prod data, anything money-touching). Approval in one context doesn't extend to the next.

## {{PROJECT}}-specific conventions
- _Add build/test/deploy discipline, branch strategy, and any non-negotiable
  correctness/safety/money rules for this project._

## Tooling defaults
- Prefer terse, low-token communication; write normal prose in code/commits/PRs/security notes.
- Lean on cross-session memory tooling (e.g. claude-mem) when available.
