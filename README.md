# Zelarion Skillpack

One link that unpacks a full Claude Code skill setup on any machine: orchestration, frontend and 3D design,
spec-driven development, security review, video and research tools. 87 skills and 10 spec-kit skills ship in this repo, and 10
more arrive as plugins from their own authors.

## Install on a new device

Paste this to Claude Code on the new machine:

> Clone https://github.com/Zelarion/zelarion-skillpack and install it by following its CLAUDE.md.

Or do it by hand:

```bash
git clone https://github.com/Zelarion/zelarion-skillpack
cd zelarion-skillpack
./install.sh --dry-run     # see what it will do
./install.sh               # do it
```

Windows without a bash prompt: `powershell -ExecutionPolicy Bypass -File .\install.ps1`
(needs Git for Windows, which Claude Code needs anyway). Restart Claude Code afterwards.

The installer never deletes. A skill folder that already exists is moved to
`~/.claude/skills/.skillpack-backup/<time>/` before the new one is copied. Re-running is safe.

| Option | Effect |
|---|---|
| `--dry-run` | Print every step, change nothing |
| `--setup-deps` | Also install tool dependencies: `uv tool install graphifyy`, gstack `./setup` (needs bun), teardown `npm run setup` |
| `--claude-md` | Append `claude-md/global-workflow.md` (plan first, sonnet builders, security rules) to `~/.claude/CLAUDE.md` |
| `--no-plugins` / `--no-external` | Skip plugin installs / git clones |

## What you get

| # | Skill | Where it comes from | Command |
|---|---|---|---|
| 1 | Orchestration | `skills/orchestrate` | `/orchestrate` |
| 2 | Agentview | `skills/agentview` | `/agentview` |
| 3 | Playwright | plugin `playwright-skill` | `playwright-skill:playwright-skill` |
| 4 | Firecrawl | plugin `firecrawl` (needs login, see below) | `firecrawl:firecrawl` |
| 5 | Caveman | plugin `caveman` | `/caveman` |
| 6 | Graphify | `skills/graphify` | `/graphify` |
| 7 | Scroll-jack 3D transitions | `skills/scrolljack-3d-transitions` | auto / name |
| 8 | Elegant design with 3D | `skills/elegant-design-with-3d` | auto / name |
| 9 | Image to Three.js | `skills/img2threejs` | auto / name |
| 10 | SaaS | `skills/saas` | `/saas` |
| 11 | Gstack | gstack command skills in `skills/` + `gstack` clone | `/qa` `/ship` `/review` `/browse` ... |
| 12 | Hyperframes | `skills/hyperframes*` (9 folders), `media-use` | `/hyperframes` |
| 13 | Grill me | `skills/grilling` | `/grilling` |
| 14 | Teardown | clone of `elvarofficial/teardown` | `/teardown` |
| 15 | All frontend skills | see "Frontend" below | |
| 16 | Cloudflare security | `skills/security-audit` (cloudflare/security-audit-skill) | `/security-audit` |
| 17 | Setup .claude folder | `skills/setupdotclaudefolder`, `skills/self-improving-memory`, plugin `setupdotclaude` | `/setupdotclaudefolder` |
| 18 | Elegant design for system | `skills/elegant-design-for-system` | auto / name |
| 19 | Speckit | `speckit/speckit-*` (10 skills) + project scaffold | `/speckit-specify` ... |
| 20 | Anti-flop | `skills/anti-flop-design-system` | `/anti-flop-design-system` |

**Frontend (item 15):** `vgldesign`, `vgldesign-watermelon`, `design-md-library` (74 real design systems),
`screenshot-to-code`, `scroll-world`, `design-consultation`, `design-html`, `design-review`, `design-shotgun`,
`plan-design-review`, `anti-flop-design-system`, `elegant-design-*`, `img2threejs`, `scrolljack-3d-transitions`,
plus plugins `impeccable`, `taste-skill`, `ui-ux-pro-max` and `frontend-design`.

**Also included:** the rest of the gstack suite (`autoplan`, `plan-*-review`, `qa`, `ship`, `land-and-deploy`,
`investigate`, `retro`, `cso`, ...), `watch` (video to answers), `research`, `scrape`, `make-pdf`,
`codebase-design`, `domain-modeling`, `improve-codebase-architecture`, `startproject`, `skillify`, and the iOS set.

## After install (things a clone cannot carry)

- **agentview** needs a Groq key in `~/.config/watch/.env` (`GROQ_API_KEY=...`, `chmod 600`). See `.env.example`.
- **firecrawl** must be authorized on each machine (`/mcp` inside Claude Code).
- **graphify** needs `uv tool install graphifyy`. **gstack** `/browse` needs bun and its `./setup`.
  **teardown** needs `npm run setup` (installs Playwright's Chromium). `--setup-deps` does all three.
- **speckit** skills expect a `.specify/` folder in the project. Use `specify init`, or
  `scripts/speckit-scaffold.sh` for an offline copy of the templates. Run `/speckit-constitution` first.
  The bundled scripts are PowerShell (`pwsh` on macOS and Linux).
- Hyperframes, img2threejs and others have their own tool needs (ffmpeg, node, python). Each `SKILL.md` lists them.

## Layout

```
skills/            vendored skill folders, copied to ~/.claude/skills/
speckit/           speckit-* skills and the .specify scaffold
plugins.txt        third-party plugins, installed with `claude plugin install`
external.txt       repos cloned into ~/.claude/skills (gstack, teardown, notebooklm)
claude-md/         optional global workflow rules
install.sh, install.ps1, scripts/
NOTICE.md          who made what, and licences
```

## Credits and licences

Original work here is MIT (see `LICENSE`). Third-party skills keep their own licences and are credited in
`NOTICE.md`. This pack redistributes them for convenience; if you are an author and want one removed, open an issue.
