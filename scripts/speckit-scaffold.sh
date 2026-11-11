#!/usr/bin/env bash
# Give a project the .specify/ folder the speckit-* skills expect, from the copy the installer
# left in <claude config>/speckit-scaffold. Prefer the official `specify init` when available.
#   scripts/speckit-scaffold.sh [project-dir]     (default: current directory)
set -euo pipefail
SRC="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/speckit-scaffold"
DEST="${1:-.}/.specify"
[ -d "$SRC" ] || { echo "run ./install.sh first ($SRC missing)" >&2; exit 1; }
[ ! -e "$DEST" ] || { echo "$DEST already exists; not overwriting" >&2; exit 1; }
mkdir -p "$DEST/memory"
cp -R "$SRC/specify-templates" "$DEST/templates"
cp -R "$SRC/specify-scripts" "$DEST/scripts"
cp -R "$SRC/specify-workflows" "$DEST/workflows"
echo "Created $DEST. Next: /speckit-constitution to write .specify/memory/constitution.md"
