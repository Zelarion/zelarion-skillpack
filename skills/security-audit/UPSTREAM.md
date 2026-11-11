# Upstream

- Source: https://github.com/cloudflare/security-audit-skill (MIT, see LICENSE), commit c1c8a8c, installed 2026-11-02.
- Installed by `git clone` and manual copy, not `npx skills add`.
- Left out: `validate-findings.test.cjs` and `validate-coverage-ledger.test.cjs` (upstream test suites, not used at runtime).
- Local change: `disable-model-invocation: true` in SKILL.md, so the skill runs only when invoked as `/security-audit`.

## Review before install

- `validate-findings.cjs` and `validate-coverage-ledger.cjs` require only Node's `fs`, `path` and `util`, and only read the file passed to them. No network, child processes, file writes or eval.
- The Markdown files run no commands other than those two validators. No URLs to fetch, no install steps, no hidden Unicode or HTML comments.

## Use

- Use it before handing a client system over (the full audit), or for a focused review of one area (guidance mode).
- Point it at source code only. Never at a live site, a hosting control panel or a client's server.
- Windows has no OS sandbox here, so leads that need target code to run stay `needs_validation`. That is the intended safe behavior.
- Reports go to `~/security-audit-skill/<repo>/run-<N>/`, outside the audited repo.
- For a routine check, use `/cso` instead: it runs as a single agent and costs much less.

To update: re-clone, diff against this folder, review the diff, then copy. Keep the local change.
