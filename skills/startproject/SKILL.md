---
name: startproject
description: Bootstrap a brand-new app project end-to-end in one orchestrated pass — from spec docs to a working, verified app. Use whenever the user says /startproject, "start this project", "bootstrap this app", "set up and build this project", or points at a folder of PRD/spec/design docs and wants a working codebase out the other side. Covers: .claude self-improving memory setup (lean CLAUDE.md index + rules + lessons + Stop hook), committing a DESIGN.md visual system from taste references, orchestrating parallel sonnet builder subagents with pinned file contracts, verification (typecheck/lint/bundle/boot), knowledge-graphing the docs, and recording lessons. Trigger this even if the user only asks for part of it (e.g. "scaffold the app from the PRD") — the procedure degrades gracefully to the relevant stages.
---

# /startproject — Spec docs → working app, one orchestrated pass

You are the **orchestrator**: you plan, pin contracts, review, and falsify. Sonnet
subagents do bulk implementation. You never hand-write the app's feature code yourself —
your hands touch only contracts, config hot-files, and fixes found in review.

## Stage 0 — Recon (cheap, parallel)
- List the project directory; read every spec/brief doc present (PRD, PRODUCT.md, tech
  stack guide). For big docs, grep headings first, then read only load-bearing sections
  (design language, IA/navigation, MVP phasing).
- View image assets (logo, design references) with the Read tool — they set taste.
- Identify: platform + stack, MVP feature cut, design direction, non-negotiables
  (a11y gates, offline rules, money-handling rules).

## Stage 1 — Memory system (.claude)
Run the `self-improving-memory` skill (or replicate its shape):
- `CLAUDE.md` = lean index (<100 lines): what-this-is, commands, non-negotiables,
  `@.claude/rules/*.md` imports.
- `.claude/rules/`: `conventions.md` (verification gate + orchestration model),
  `architecture.md` (folder layout + layering rules), `design-system.md` (tokens, a11y
  gates, voice), `security.md` (secrets, error handling, race safety), `lessons.md`
  (append-only, newest on top).
- `.claude/hooks/lesson-guard.js` + `settings.json` Stop hook so lesson capture is
  enforced, not remembered.
- Record in the rules where the logo and design-reference images live.

## Stage 2 — DESIGN.md (commit the visual system)
Load a frontend-design skill for calibration, then write repo-root `DESIGN.md` that
**commits** (not suggests): design thesis + one signature element; full token table
(colors WITH verified ≥4.5:1 contrast — darken spec colors that fail; type roles;
radius/spacing/motion); concrete implementation recipes for the chosen stack (e.g. RN
0.76+ `boxShadow` incl. inset for neumorphism); the named shared primitives; per-screen
language; and an explicit "banned" list (AI-default palettes, shadow-only affordances,
default Material look). Builders implement this file verbatim — no inventing tokens.

## Stage 3 — Scaffold + pinned contracts (orchestrator's hands)
1. Scaffold with the stack's official generator **in the background** while doing
   Stage 2 (e.g. `npx create-expo-app@latest <name> --template default --no-install`
   then `npm install`).
2. **Single-writer rule:** only YOU touch `package.json`/`app.json`/config. Install ALL
   deps up front (storage, haptics, fonts, lint tooling) so no builder ever runs npm.
3. **Pin cross-builder contracts as real files before dispatch** — this is why parallel
   builders integrate cleanly: shared domain types (`src/core/domain.ts`), a storage-key
   registry (`src/core/storage/keys.ts`), and the exact barrel export names each feature
   must expose. Import-path mismatches are the #1 parallel-build failure; kill them here.

## Stage 4 — Builders (sonnet subagents, disjoint dirs)
- **Builder 1 (synchronous — everything depends on it):** theme tokens verbatim from
  DESIGN.md, shared UI primitives (with a11y contract baked in: non-depth affordances,
  48dp targets, required labels), core utils (money = integer minor units with exact-sum
  split; race-safe serialized storage writer; id gen), i18n strings.
- **Builders 2–N (parallel, background):** one per disjoint feature group. Typical split:
  (a) routes/navigation shell + home + profile, (b) 1–2 social features, (c) remaining
  tool features. Route files are thin; MVVM: dumb components / ViewModel hooks /
  class repositories over local storage with seeded demo data.
- Every builder prompt states: exact dirs OWNED (touch nothing else), files to read first
  (DESIGN.md, architecture rules, core contracts), exact export names, discipline
  (TS strict, no `any`, ≤300 lines/file, JSDoc per export), and "run `npx tsc --noEmit`,
  fix YOUR dirs only; errors in parallel builders' dirs are expected — ignore."
- If a subagent dies mid-task (API error, spend limit), **resume it via SendMessage**
  with a disk-state summary of what already landed — don't redispatch cold.

## Stage 5 — Verify (you, never trust builder reports)
Run yourself and quote real output:
1. `npx tsc --noEmit` → must be exit 0.
2. Lint (install the linter if the template omits it); fix trivial warnings inline.
3. Production bundle export (e.g. `npx expo export --platform android`) — proves
   end-to-end module resolution.
4. Boot the dev server, curl the manifest/root endpoint for HTTP 200, kill it.
5. Adversarial read of load-bearing files: money math edge cases, storage race safety,
   splash/font gating, navigation wiring, token fidelity to DESIGN.md.

## Stage 6 — Knowledge graph (optional but default-on)
Run the `graphify` skill on the repo root. Windows gotchas already learned:
verify the shell's cwd before detect (it drifts); Python multiprocessing scripts need
`if __name__ == '__main__':` guards or extraction silently degrades; skip template
asset icons from vision extraction — only brand images carry knowledge.

## Stage 7 — Lessons + report
- Append every gotcha hit during the pass to `.claude/rules/lessons.md` (mechanism +
  fix, not changelog).
- Final report: what was built, verification evidence (quoted), design system summary,
  how to run, what's deliberately deferred.

## Failure modes to avoid
- Two builders in one file/dir; builders running installs; contracts "agreed" only in
  prompts instead of pinned files; trusting "tsc clean" claims without re-running;
  design tokens invented outside DESIGN.md; declaring done without a bundle/boot proof.
