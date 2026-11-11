# Default delivery workflow (all projects, current + future)

This is a standing instruction — the user should never have to repeat it per task.

- **Plan before building.** For any non-trivial task, produce a short plan first (scope, files,
  order, how it will be falsified) before writing code. Keep it terse.
- **Implementation runs on sonnet subagents.** Deploy `sonnet` agents to do the actual code edits.
  Split builders onto **disjoint files/dirs** so they never collide (e.g. backend vs frontend, or
  different services); serialize any work that funnels through a shared hot file.
- **Opus (the main thread) plans, researches, coordinates, reviews, and falsifies** — it does NOT
  hand-write the bulk implementation. After builders finish, opus runs the real tests/smoke/analyze,
  quotes actual output, and adversarially tries to break the result before saying "done."
- **Self-improving memory loop stays on.** Append lessons after fixing a mistake; keep project
  memory (CLAUDE.md / rules / AGENTS.md / MEMORY_BANK.md) current.
- Honor each project's own CLAUDE.md/AGENTS.md conventions; they win over this default where they
  conflict.

# Non-negotiable security & reliability rules (all projects, current + future)

Absolute, standing, never re-litigated. A change violating any of these is wrong even if it works.

1. **No double-submit, ever.** Every mutating UI control: disabled + pending state + handler
   early-return guard while a request is in flight. Idempotency keys are generated once per user
   intent (not per attempt) so retries replay, not duplicate.
2. **Every mutating endpoint is duplicate-safe** via one of: idempotency-key store,
   conditional state-transition UPDATE (side effects only in the winning transaction),
   unique constraint + out-of-transaction recovery, or a central idempotent posting layer.
   New mutating endpoints ship with a double-fire test (sequential + concurrent).
3. **Fail closed.** Unrecognized enum/state/route in a validation chain = reject, never pass.
4. **Validate at the boundary** (schema validation, e.g. zod); parameterized queries only;
   server recomputes money/quantities — never trust client-sent prices, roles, or scope.
5. **Server-side authz on every route**; rate-limit auth; generic auth errors; constant-time
   secret comparison; HMAC over exact raw bytes.
6. **Never log or return secrets/tokens/PII.** Secrets live in env/gitignored files only.
7. **No fire-and-forget side effects**: crash-surviving work goes through an outbox/queue with
   lease claim + bounded retry to a terminal state.
8. When starting a new project's `.claude` setup, use `/setupdotclaudefolder` (not `/init`) —
   it installs these rules plus the self-improving-memory loop and the dotclaude kit.

# Engineering standards — write it like company code (all projects, current + future)

Standing, never re-litigated. The bar is NOT "the code runs". The bar is that a future developer
who has never met me can read it, debug it at 2am, change it when the requirement changes, and
scale it. Code is written once and maintained for years — optimize for the reader.

- **CLEAN** = readable, changeable, maintainable. Not "short", not "nicely formatted". Four tests:
  will another dev understand it; is it easy to debug; is it easy to change when a new requirement
  lands; is there unnecessary duplication. Comments explain WHY, never WHAT. Delete dead code.
- **EFFICIENT** = does what is needed without wasting resources, across ALL axes — time, memory,
  database queries, network requests, CPU, scalability. Never fetch 500,000 rows to show 10. No
  N+1 queries. Index what you filter/sort/join on. Ask what happens at 100x.
- **AI-generated code is the highest-risk code in the repo** — it can look clean while being wrong,
  and it is the code most likely to be merged unread. Looking clean and being correct are unrelated
  properties. Review every generated block for readability, maintainability, performance, security,
  unnecessary complexity, and scalability — and verify the APIs/fields it used actually exist
  instead of being plausible guesses. "It works" is the START of review, not the end.
- Never present passing output as proof of quality. Run it, read the diff, try to break it.
  If I cannot explain a line I am shipping, I do not ship it.

Full rule text: `~/.claude/skills/setupdotclaudefolder/assets/engineering-standards.template.md`,
installed to `.claude/rules/engineering-standards.md` in every project by `/setupdotclaudefolder`.

# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.

# Always label files with their location (all projects, current + future)

Standing instruction. Whenever a file is handed over, referenced, or reported as produced,
state WHERE it is. A filename on its own is not enough: I have to be able to find it,
open it, or attach it to an email without asking a follow-up question or searching for it.

- **Every file mentioned carries its path.** Repo-relative from the project root is the
  default. Use an absolute path when the file sits outside the project (a scratchpad, a
  Downloads folder, a temp directory), because relative means nothing there.
- **When listing several deliverables, show the location for each one**, not a shared
  "these are all in X" sentence above the list. Each row stands on its own.
- **In a table of outputs, the path gets its own column or sits in the label.** Do not
  make me match a bare name against a folder listing.
- In editors that render clickable links (the VS Code extension, for example), keep using
  markdown link syntax, but the visible link text is the path, not a friendly name.
- This applies to files created, modified, moved, downloaded, generated, or merely
  pointed at. It applies in the middle of a message, not only in a final summary.

