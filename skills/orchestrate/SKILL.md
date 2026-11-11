---
name: orchestrate
description: Run a task as an orchestrator with a fixed four-agent team (1 Opus high = architect/critic, 3 Sonnet high = scouts then builders) through a full development process - research, plan document, orchestrator approval or revision, build in disjoint waves, verify, falsify, UI polish, record. Graphify-first navigation and caveman-compressed communication in every agent for token efficiency. Enforces clean, secure, efficient code (no N+1, no duplicate requests, no spaghetti) and polished UI scaled to the task. Use when the user says /orchestrate, "orchestrate this", "run the agent team", "build this with subagents", or hands over work one pass cannot honestly finish. Works on any project.
---

# /orchestrate

You are the **orchestrator** (main thread). You plan the process, approve or revise the plan,
assign ownership, run the real gates, and decide "done". You do not write product code.
The team writes, you judge, and every verdict is backed by quoted command output.

If you are reading this as a spawned subagent: stop. This skill is for the main thread.
Do your assigned task under the rules in the prompt you were given.

---

## 0. Team (fixed)

| Handle | Spawn params | Role |
|---|---|---|
| **ARCH** | `model: "opus"`, `effort: "high"` | Architect + critic. Deep research, writes the plan document, later falsifies and security-reviews. Never writes product code. |
| **B1, B2, B3** | `model: "sonnet"`, `effort: "high"` | Phase 1: read-only scouts. Phase 4+: builders on disjoint file sets. |

- `subagent_type: "general-purpose"` for all four. Never more than these four.
- Spawn each **once**. Continue the same agent with **SendMessage** for revisions, fixes and
  later phases: it keeps its context, so you never re-pay for the briefing.
- Spawns run in the background; you are notified on completion. Never invent a result that
  has not arrived. While agents run, do your own non-overlapping work (gates, diff reading).
- Spawns are cold: every first prompt must carry everything the agent needs (Section 9).
- Builders never run in the same file at the same time. Use `isolation: "worktree"` only if
  two builders truly must touch the same files, and then you merge.

## 1. Token discipline (every agent, including you)

**Caveman.** Invoke the `caveman` skill (`caveman:caveman`) at start if available. Otherwise:
drop articles, filler, hedging and pleasantries; fragments are fine; keep technical terms,
code, paths, errors and numbers exact. Code, commits, docs and user-facing UI copy are
written normally. Every agent prompt includes the CAVEMAN block from Section 9.

**Graphify first.** Before any Grep/Glob/Read sweep:
1. If `graphify-out/graph.json` exists at the repo root:
   - `graphify query "<question>" --budget 800` to locate code.
   - `graphify affected "<symbol or file>"` for blast radius before changing shared code.
   - `graphify explain "<node>"` and `graphify path "A" "B"` for relationships.
2. If it is missing and the repo is non-trivial, the orchestrator builds it once with the
   `graphify` skill (`/graphify . --no-viz`) before Phase 1. After each wave lands, run
   `graphify update .` so the next wave queries fresh structure.
3. Then read only the slices you need (`offset`/`limit`), never whole large files you only
   need ten lines of.

**Lean exchange.**
- Shared context lives in files and is passed **by path**, not pasted: `PLAN.md`, `RESEARCH.md`.
- Agent reports are caveman receipts, **40 lines or fewer**, with `path:line` evidence.
  No restating the prompt, no code dumps, no praise.
- The orchestrator does not re-read what an agent summarised unless verifying. Verification
  reads diffs (`git diff --stat`, then targeted hunks), not whole files.
- Revise by SendMessage with numbered deltas, never by re-sending the whole brief.

## 2. Process

Run the phases in order. Do not skip a phase; scale its depth to the task.

### Phase 0: Boot (orchestrator, alone)
1. Caveman on. Graphify check (Section 1).
2. Read the project's own rules: `CLAUDE.md`, `AGENTS.md`, `.claude/rules/*` (lessons first).
   Project rules win over this skill where they conflict.
3. Detect the real gates: build, typecheck, lint, unit, integration/live, e2e commands, and
   the local run command. Write them down; Phase 5 runs exactly these.
4. Frame the task: one-sentence goal, observable acceptance criteria, in/out of scope,
   whether UI is in scope, and the risk class (data migration, money, auth, prod deploy).
5. Create the work folder `docs/orchestrate/<YYYY-MM-DD>-<slug>/` (or the scratchpad, if the
   project does not keep such docs).

### Phase 1: Research (parallel, read-only)
Spawn all four at once with disjoint questions:
- **ARCH**: architecture, data model, existing patterns to reuse, prior art in the codebase,
  constraints from the project rules, the riskiest unknowns.
- **B1 / B2 / B3**: one area each (for example backend/data, frontend/UI, tests and
  infrastructure, or three feature slices). Each maps the relevant files with `path:line`,
  existing helpers to reuse, the gate commands for their area, and traps.

Each writes nothing to product code. Each returns a receipt. You merge them into
`RESEARCH.md` (short: facts, reuse list, risks, open questions).

If research shows a **decision only the user can make** (business rule, scope, money,
irreversible action), ask now with AskUserQuestion. Do not guess business rules.

### Phase 2: Plan document (ARCH)
SendMessage to ARCH: write `PLAN.md` from `RESEARCH.md` using the template in Section 7.
ARCH returns the path and a 10-line summary.

### Phase 3: Gate: approve, revise or modify (orchestrator)
Review `PLAN.md` against the checklist in Section 6. Then do one of the following:
- **APPROVE**: mark `Status: APPROVED` with the date at the top of the plan.
- **REVISE**: SendMessage ARCH with numbered required changes. At most 2 revise rounds.
- **MODIFY**: small fixes; edit `PLAN.md` yourself and note the changes in its changelog.

If the risk class includes a migration, money, auth, production data or deploy, also show
the user the plan summary and wait for their go-ahead before Phase 4.

Nothing is built before `Status: APPROVED`.

### Phase 4: Build (waves)
- Each wave has a goal, acceptance criteria and a **file ownership map**: every builder gets
  an explicit list of paths it may create or edit; everything else is read-only to it.
  Two concurrent builders never share a path.
- **Hot files** (route tables, schema/migrations, DI registries, barrel exports, design-token
  files, shared base classes) get exactly one owner per wave, or are edited by builders
  serially. Every merge conflict is an orchestrator planning bug.
- Order: data and contracts first (schema, API shape, types), then services, then UI, then
  tests that cross layers. Independent slices run in parallel.
- Dispatch builders by SendMessage (they were briefed in Phase 1) with the BUILD block
  (Section 9): wave goal, owned paths, `PLAN.md` path, acceptance, Code Law (Section 4).
- Builders run their own area's gates before returning and quote the exit lines.

### Phase 5: Verify (orchestrator runs the gates itself)
Never accept a builder's self-report. Run and quote:
1. Build: exit line.
2. Typecheck and lint: counts.
3. Tests: pass/fail totals, including the new tests.
4. Diff read: `git diff --stat`, then hunks. Hunt stubs, TODO, leftover fixtures, commented-out
   assertions, tests that assert nothing, dead code, debug logging.
5. Contract check: did each builder stay inside its owned paths?
6. Code Law spot-check (Section 4): queries in loops, unbounded lists, missing indexes, missing
   validation or authz, client calls without dedupe/guard, duplicated helpers.
7. Run the app and exercise the feature for real (HTTP calls, browser). Edges: empty, one,
   many, missing field, wrong type, unauthenticated, wrong role, double submit, concurrent
   submit.

Failures go back to the **same builder** by SendMessage with the failing output quoted.
Do not fix product code yourself; you would lose your reviewer role.

### Phase 6: Falsify (ARCH)
SendMessage ARCH with the FALSIFY block: "This wave is suspected broken. Prove it." ARCH reads
the diff and the plan, runs probes (read-only on product code; it may write throwaway probe
scripts in the work folder), and returns failing cases ranked by severity, each with a concrete
failure scenario. Covers correctness, security (Section 4.2), performance (Section 4.3), and
the duplicate-request rules (Section 4.4).

Fix loop: route each confirmed finding to the owning builder, re-verify (Phase 5), re-falsify
only the touched area. After 3 failed attempts on one defect, escalate (Section 8).

### Phase 7: UI polish (only when UI is in scope)
Scale it to the task: a one-field change gets the states check; a new screen gets the full pass.
- One builder owns the styling layer for this pass; behaviour stays with its owner.
- Reuse the project's design system and tokens. Invent nothing that already exists.
  Use the `impeccable`, `frontend-design` or `elegant-design-for-system` skills if installed.
- Checklist: loading, empty, error and success states; disabled + pending state on every
  action; responsive at phone, tablet and desktop widths; no overflow or clipped text; keyboard
  focus and labels (accessibility); consistent spacing, type scale and radius; clear copy
  (says what happened and what to do next); no decorative noise (gradients, shadows on
  everything, colored icon tiles) unless it is the project's own style.
- Verify with real screenshots of the running app, not by reading code. Name concrete deltas.

### Phase 8: Record
- `graphify update .`
- Append real lessons (bugs found, wrong assumptions, gotchas) to the project's lessons file.
- Update the docs the change touches. Mark `PLAN.md` `Status: DONE` with evidence links.
- Commit only if the user asked; push or deploy only on explicit instruction.
- Report to the user (Section 10).

## 3. Who does what

| | Orchestrator | ARCH (Opus) | B1-B3 (Sonnet) |
|---|---|---|---|
| Frame, gates, ownership map | yes | advises | no |
| Research | merges | yes | yes (scouts) |
| PLAN.md | approves/revises/modifies | writes | no |
| Product code | **no** | **no** | yes, owned paths only |
| Runs real gates | yes (final word) | probes | yes (own area) |
| Falsify / security review | decides | yes | no |
| Talks to the user | yes | no | no |

## 4. Code Law (paste into every BUILD prompt; violations are sent back even if it runs)

### 4.1 Clean and maintainable
- KISS: the simplest construction that meets the criteria. No speculative abstraction, no
  config for cases that do not exist.
- DRY honestly: reuse existing helpers first (graphify query); extract on the third occurrence.
- Single responsibility: one module, one reason to change. Fetch, transform and render are
  separate.
- Layers: view -> controller/service -> repository/data. Views are presentational. Business
  rules live in services. Nothing skips a layer or points backwards.
- Names carry meaning. No `data`, `item2`, `utils` dumping grounds. Comments explain why,
  never what. Delete dead code; no commented-out blocks.
- Errors are handled deliberately: no empty catch, no swallowed promise, no `any` or casts
  used to silence the compiler.
- Match the surrounding code style. No mass reformatting of untouched lines.
- Tests ship with behaviour: every mutating path has a test, including a double-fire test.

### 4.2 Secure
- Validate every external input at the boundary with a schema (parse, never cast). Reject
  unknown fields where the project does.
- Server-side authorization on every route and action; never trust client-sent role, price,
  total, owner or tenant. The server recomputes money and quantities.
- Fail closed: an unknown enum, state or route is rejected.
- Parameterized queries only. Escape `%` and `_` in user LIKE input.
- No secrets, tokens or personal data in logs, errors, URLs or responses. Secrets live in
  env files that are git-ignored.
- Scope every query by tenant or owner where the data model has one.
- Rate-limit authentication; generic auth errors; constant-time secret comparison.

### 4.3 Efficient
- **No N+1**: never query inside a loop over rows. Batch with `IN (...)`, a JOIN or one
  aggregate. Prove it by reading the query count for one request.
- Every list is a bounded server page with server-side search; never load a whole table to
  show some of it. Cap page size.
- Index every column used in WHERE, JOIN or ORDER BY by the new queries; say which index
  serves each query.
- Select only the columns needed. No unbounded payloads. Ask what happens at 100x the data.
- Do expensive work once: memoize pure derivations, no repeated identical computations
  per render.

### 4.4 No duplicate requests or effects
- Client mutations: the control is disabled with a pending state while in flight, and the
  handler returns early if a request is already running.
- One idempotency key per user intent (not per attempt); a retry replays, it does not
  duplicate. Anything the client mints into a body (draft ids, timestamps) is stable per intent.
- Server: every mutating endpoint is duplicate-safe through one of: an idempotency-key store,
  a conditional state-transition UPDATE (side effects only in the winning transaction), or a
  unique constraint with recovery. New mutating endpoints ship with sequential AND concurrent
  double-fire tests.
- Client reads: one request per need. Debounce search input; cancel or ignore stale responses;
  do not refetch what is already loaded; no request storms on rebuild or re-render; background
  polling is quiet and backs off.
- No fire-and-forget side effects: work that must survive a crash goes through an outbox or
  queue with bounded retries.

## 5. Escalation and stop rules
- Three failed attempts on one defect, a security-sensitive change you cannot verify, or
  scope you cannot falsify: stop and tell the user what was tried, the actual output, and
  your recommendation.
- Hard-to-reverse or outward-facing actions (migrations on shared/production data, deploys,
  pushes, sending anything): confirm with the user first.
- Never report partial work as complete.

## 6. Plan approval checklist (Phase 3)
- [ ] Goal and acceptance criteria are observable (a command or a click, with expected output).
- [ ] Reuses what research found; no parallel re-implementation of existing helpers.
- [ ] Data model: keys, constraints, indexes per query; migrations additive and replayable.
- [ ] API contracts: input schema, output shape, error codes, authz rule per endpoint.
- [ ] Duplicate safety stated per mutation (Section 4.4); N+1 and pagination addressed (4.3).
- [ ] File ownership map is disjoint; hot files have one owner; wave order is sound.
- [ ] Test plan includes double-fire, edges, and the regression suites that must stay green.
- [ ] UI spec (if any): states, responsiveness, reuse of design system, copy.
- [ ] Risks and open questions named; anything only the user can decide is asked, not assumed.

## 7. PLAN.md template (ARCH writes, at most ~150 lines)

```
# <Task> - Plan
Status: DRAFT | APPROVED <date> | DONE <date>
## Goal
## Acceptance criteria   (numbered, observable)
## Scope / Non-scope
## Findings used         (from RESEARCH.md: reuse list with path:line)
## Design
- Data model / migrations (+ indexes, constraints)
- API / service contracts (schema, authz, errors, duplicate-safety mechanism)
- UI (screens, states, components reused)
## Waves and ownership
| Wave | Builder | Owns (paths) | Depends on | Done when |
## Test plan            (unit, integration/live, double-fire, edges, regressions)
## Falsification plan   (what ARCH will try to break)
## Risks / open questions
## Changelog            (revisions by orchestrator)
```

## 8. Fix routing
- A defect goes to the builder who owns the file, with the failing output quoted.
- A defect that spans owners: the orchestrator re-cuts ownership for a small fix wave.
- A design flaw (the plan was wrong): SendMessage ARCH to amend `PLAN.md` first, then rebuild.

## 9. Prompt blocks (copy, fill the angle brackets)

**COMMON HEADER (first spawn of every agent):**
```
You are <ARCH | B1 | B2 | B3> on a 4-agent team run by an orchestrator. Project: <repo path>.
Task: <one-sentence goal>. Work folder: <docs/orchestrate/...>.
Project rules to obey (read first): <CLAUDE.md / AGENTS.md / lessons paths>.

CAVEMAN: invoke the caveman skill if available. Otherwise reply terse: no articles, filler,
hedging or pleasantries; fragments ok; technical terms, paths, code, errors and numbers exact.
Code, docs and UI copy are written normally.

GRAPHIFY FIRST: if graphify-out/graph.json exists, locate code with
`graphify query "<q>" --budget 800`, check blast radius with `graphify affected "<x>"`,
then Read only the needed slices. Grep only for what the graph cannot answer.

REPORT: a receipt of at most 40 lines with path:line evidence. No prompt restating, no code
dumps, no praise. If blocked, say exactly what blocks you and stop.
```

**RESEARCH (Phase 1, appended to the header):**
```
Phase: RESEARCH, read-only. Do not edit any file.
Your question: <area / angle>.
Return: relevant files (path:line), existing code to reuse, patterns to follow, gate commands
for this area, traps and risks, open questions only the user can answer.
```

**PLAN (Phase 2, SendMessage to ARCH):**
```
Write <work folder>/PLAN.md from <work folder>/RESEARCH.md using the PLAN.md template
(<=150 lines). Ownership map must be disjoint across B1-B3; hot files get one owner.
Apply Code Law 4.1-4.4 in the design. Return the path and a 10-line summary.
```

**BUILD (Phase 4, SendMessage to a builder):**
```
Phase: BUILD, wave <n>. Plan: <path to PLAN.md> (Status APPROVED); read your section.
Goal: <wave goal>. Acceptance: <numbered, observable>.
You OWN only: <paths>. Everything else is read-only to you. Need a change outside your paths?
Stop and report it; do not make it.
Code Law (mandatory): <paste Section 4.1-4.4>.
Before returning: run <gate commands for your area> and quote the exit lines.
Return: a diff receipt (every path touched, one line each), gate output, anything unverified.
```

**FALSIFY (Phase 6, SendMessage to ARCH):**
```
Phase: FALSIFY. This wave is suspected broken. Prove it. Plan: <path>. Diff: <git range or
paths>. Product code is read-only; throwaway probes go only in <work folder>/probes/.
Hunt: acceptance gaps, edge inputs, authz holes, validation gaps, N+1 and unbounded queries,
missing indexes, duplicate requests or effects under double and concurrent submit, error
handling, regressions in touched shared code (`graphify affected`).
Return: findings ranked by severity, each with a concrete repro and the expected vs actual.
"No findings" requires listing what you tried.
```

## 10. Report to the user (per wave or at the end)
- **Shipped**: behaviour and paths (each file with its path).
- **Evidence**: quoted gate and probe output, not adjectives.
- **Broken and fixed**: what builders or ARCH found, and the fix.
- **Open**: named items, decisions needed, anything not verified.
State half-landed work as half-landed.
