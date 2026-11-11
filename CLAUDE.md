# Zelarion Skillpack: instructions for Claude

This repo is a portable bundle of Claude Code skills. If the user pastes this repo's link and asks
you to install, unpack or set it up, do exactly this:

1. Clone it (or use the clone you are in) and `cd` into it.
2. Run `./install.sh --dry-run` and show the user the summary.
3. Run `./install.sh` (Windows: `powershell -ExecutionPolicy Bypass -File .\install.ps1`).
   Add `--setup-deps` and `--claude-md` only if the user asks for them.
4. Tell the user to restart Claude Code, and list anything the script printed as skipped or failed.
5. Secrets are never in this repo. For agentview and firecrawl, point the user at `.env.example`.

Do not edit files under `skills/` to "improve" them while installing; they are vendored copies.
What is inside and where it came from: `README.md`, `NOTICE.md`.
