# Notice: provenance and licences

Skills in `skills/` are copies taken from a working Claude Code setup. Provenance below is what each
folder's own `UPSTREAM.md`, `LICENSE` or `SKILL.md` records; folders not listed carry no recorded
upstream and are treated as written by the pack owner (MIT, see `LICENSE`). Fix any gap by opening an issue.

| Folder(s) | Source | Licence |
|---|---|---|
| `grilling`, `codebase-design`, `domain-modeling`, `improve-codebase-architecture` | https://github.com/mattpocock/skills | MIT |
| `security-audit` (Cloudflare security skill; local change: runs only when invoked) | https://github.com/cloudflare/security-audit-skill | MIT |
| `img2threejs` | see `skills/img2threejs/LICENSE` | Apache-2.0 |
| `scroll-world` | see `skills/scroll-world/LICENSE` | MIT |
| `design-md-library` | https://github.com/VoltAgent/awesome-design-md (transcribed public design systems; brand names belong to their owners) | per source |
| `watch` | https://github.com/bradautomates/claude-video | see source |
| `hyperframes*`, `media-use` | HyperFrames / HeyGen | see each `SKILL.md` |
| gstack command skills (`autoplan`, `qa`, `ship`, `review`, `browse`, `cso`, `plan-*-review`, `design-*`, `land-and-deploy`, `investigate`, `retro`, `ios-*`, `spec`, `scrape`, `skillify`, ...) | https://github.com/garrytan/gstack | MIT |
| `graphify` | https://pypi.org/project/graphifyy/ | see source |
| `setupdotclaudefolder` | composes https://github.com/poshan0126/dotclaude | see source |
| `speckit/*` | https://github.com/github/spec-kit | MIT |

Cloned at install time, not stored here: `gstack`, `teardown` (https://github.com/elvarofficial/teardown, MIT),
`notebooklm` (https://github.com/PleasePrompto/notebooklm-skill).

Installed as plugins from their authors' repos (see `plugins.txt`): caveman (juliusbrussee), impeccable (pbakaus),
taste-skill (leonxlnx), ui-ux-pro-max (nextlevelbuilder), playwright-skill (lackeyjb), dotclaude (poshan0126),
and Anthropic's frontend-design, skill-creator, superpowers, firecrawl.

Removed before publishing: private notes skills (`vps-sync`, `weekly-brief`, `risk-scan`), client-specific
reference files, and all absolute local paths.
