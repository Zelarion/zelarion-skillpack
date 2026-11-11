#!/usr/bin/env bash
# Zelarion Skillpack installer. Works in Git Bash (Windows), macOS and Linux.
#
#   ./install.sh                 skills + third-party plugins + external repos
#   ./install.sh --dry-run       print what would happen, change nothing
#   ./install.sh --setup-deps    also install tool dependencies (uv graphifyy, gstack/teardown setup)
#   ./install.sh --claude-md     also append the workflow rules to ~/.claude/CLAUDE.md
#   ./install.sh --no-plugins    skip `claude plugin ...` steps
#   ./install.sh --no-external   skip git clones of gstack / teardown / notebooklm
#
# Safe to re-run. An existing skill folder is moved to <config>/skills/.skillpack-backup/<time>/
# before it is replaced; nothing is deleted.
set -euo pipefail

PACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SKILLS_DIR="$CLAUDE_HOME/skills"
BACKUP_DIR="$SKILLS_DIR/.skillpack-backup/$(date +%Y%m%d-%H%M%S)"

DRY_RUN=0; DO_PLUGINS=1; DO_EXTERNAL=1; DO_DEPS=0; DO_CLAUDE_MD=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --no-plugins) DO_PLUGINS=0 ;;
    --no-external) DO_EXTERNAL=0 ;;
    --setup-deps) DO_DEPS=1 ;;
    --claude-md) DO_CLAUDE_MD=1 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "unknown option: $arg (see --help)" >&2; exit 2 ;;
  esac
done

say()  { printf '%s\n' "$*"; }
run()  { if [ "$DRY_RUN" = 1 ]; then say "  [dry-run] $*"; else "$@"; fi; }

# Copy one skill folder into the skills dir, backing up whatever is there.
install_skill_dir() {
  local src="$1" name; name="$(basename "$src")"
  local dest="$SKILLS_DIR/$name"
  if [ "$DRY_RUN" = 1 ]; then
    if [ -e "$dest" ]; then say "  [dry-run] $name (exists: would back up, then replace)"; else say "  [dry-run] $name (new)"; fi
    return
  fi
  if [ -e "$dest" ]; then
    run mkdir -p "$BACKUP_DIR"
    run mv "$dest" "$BACKUP_DIR/$name"
  fi
  run cp -R "$src" "$dest"
}

say "Zelarion Skillpack -> $CLAUDE_HOME"
run mkdir -p "$SKILLS_DIR"

# 1. Skills shipped in this repo (own + vendored) and the spec-kit skills.
say "[1/5] skills"
count=0
for src in "$PACK_DIR"/skills/*/ "$PACK_DIR"/speckit/speckit-*/; do
  [ -f "${src}SKILL.md" ] || continue
  install_skill_dir "${src%/}"
  count=$((count + 1))
done
say "  $count skill folders installed"

# Spec-kit project scaffold (templates/scripts/workflows) for projects without `specify init`.
run mkdir -p "$CLAUDE_HOME/speckit-scaffold"
for part in specify-templates specify-scripts specify-workflows; do
  run cp -R "$PACK_DIR/speckit/$part" "$CLAUDE_HOME/speckit-scaffold/"
done

# 2. Third-party plugins (caveman, impeccable, taste-skill, ui-ux-pro-max, playwright-skill, ...).
if [ "$DO_PLUGINS" = 1 ]; then
  say "[2/5] plugins"
  if command -v claude >/dev/null 2>&1; then
    while IFS='|' read -r marketplace source plugin; do
      case "$marketplace" in ''|'#'*) continue ;; esac
      say "  $plugin@$marketplace"
      run claude plugin marketplace add "$source" || say "    marketplace add failed (already added?), continuing"
      run claude plugin install "$plugin@$marketplace" || say "    install failed for $plugin@$marketplace"
    done < "$PACK_DIR/plugins.txt"
  else
    say "  'claude' CLI not found on PATH; skipped. Run these later:  ./install.sh --no-external"
  fi
else
  say "[2/5] plugins skipped"
fi

# 3. External repos that carry their own code (gstack binaries, teardown simulator, notebooklm).
if [ "$DO_EXTERNAL" = 1 ]; then
  say "[3/5] external repos"
  if command -v git >/dev/null 2>&1; then
    while IFS='|' read -r name url; do
      case "$name" in ''|'#'*) continue ;; esac
      dest="$SKILLS_DIR/$name"
      if [ -d "$dest/.git" ]; then
        say "  $name: updating"
        run git -C "$dest" pull --ff-only || say "    pull failed, leaving as is"
      else
        if [ -e "$dest" ]; then run mkdir -p "$BACKUP_DIR"; run mv "$dest" "$BACKUP_DIR/$name"; fi
        say "  $name: cloning $url"
        run git clone --depth 1 "$url" "$dest" || say "    clone failed for $name"
      fi
    done < "$PACK_DIR/external.txt"
  else
    say "  git not found; skipped"
  fi
else
  say "[3/5] external repos skipped"
fi

# 4. Optional tool dependencies. Off by default: they download large toolchains.
if [ "$DO_DEPS" = 1 ]; then
  say "[4/5] dependencies"
  if command -v uv >/dev/null 2>&1; then run uv tool install --upgrade graphifyy; else say "  uv missing: install uv, then 'uv tool install graphifyy' (graphify)"; fi
  if [ -x "$SKILLS_DIR/gstack/setup" ] && command -v bun >/dev/null 2>&1; then (cd "$SKILLS_DIR/gstack" && run ./setup); else say "  gstack: needs bun, then 'cd $SKILLS_DIR/gstack && ./setup'"; fi
  if [ -f "$SKILLS_DIR/teardown/package.json" ] && command -v npm >/dev/null 2>&1; then (cd "$SKILLS_DIR/teardown" && run npm run setup); else say "  teardown: needs npm, then 'npm run setup' in $SKILLS_DIR/teardown"; fi
else
  say "[4/5] dependencies skipped (add --setup-deps; see README 'After install')"
fi

# 5. Optional global workflow rules.
if [ "$DO_CLAUDE_MD" = 1 ]; then
  say "[5/5] global CLAUDE.md"
  target="$CLAUDE_HOME/CLAUDE.md"
  marker="<!-- zelarion-skillpack:workflow -->"
  if [ -f "$target" ] && grep -qF "$marker" "$target"; then
    say "  already present"
  elif [ "$DRY_RUN" = 1 ]; then
    say "  [dry-run] append claude-md/global-workflow.md to $target"
  else
    { printf '\n%s\n' "$marker"; cat "$PACK_DIR/claude-md/global-workflow.md"; } >> "$target"
    say "  appended to $target"
  fi
else
  say "[5/5] global CLAUDE.md skipped (add --claude-md to opt in)"
fi

say "Done. Restart Claude Code, then try /skills or one of: /orchestrate /graphify /saas /agentview"
