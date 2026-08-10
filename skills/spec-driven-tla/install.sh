#!/bin/sh
# Install the spec-driven + TLA+ sub-agent workflow into a target project.
# Run from the target project root. Idempotent: re-running skips what exists.
# Usage: ~/.claude/skills/spec-driven-tla/install.sh [target-dir]
set -eu

SKILL_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TARGET=${1:-$PWD}
cd "$TARGET"
echo "== spec-driven-tla → $TARGET =="

# 1. Sub-agent definitions.
mkdir -p .claude/agents
for f in "$SKILL_DIR"/templates/agents/*.md; do
  name=$(basename "$f")
  if [ -f ".claude/agents/$name" ]; then
    echo "[ok] agent exists (kept): $name"
  else
    cp "$f" ".claude/agents/$name"
    echo "[ok] added agent: $name"
  fi
done

# 2. TLA+ model directory.
mkdir -p specs/tla
[ -f specs/tla/.gitkeep ] || touch specs/tla/.gitkeep
echo "[ok] specs/tla ready"

# 3. OpenSpec init if absent.
if [ -d openspec ]; then
  echo "[ok] openspec already initialized"
elif command -v openspec >/dev/null 2>&1; then
  openspec init && echo "[ok] openspec initialized"
else
  echo "[!!] openspec CLI not found. Install it, then run: openspec init" >&2
fi

# 4. TLA+ toolchain (JDK + jar + tlc/sany wrappers). Bundled installer first.
if command -v tlc >/dev/null 2>&1; then
  echo "[ok] tlc present"
elif [ -x "$SKILL_DIR/scripts/install-tlaplus.sh" ]; then
  echo "[..] installing TLA+ toolchain (bundled)"
  sh "$SKILL_DIR/scripts/install-tlaplus.sh"
elif [ -x "$HOME/.claude/scripts/install-tlaplus.sh" ]; then
  echo "[..] installing TLA+ toolchain (global)"
  "$HOME/.claude/scripts/install-tlaplus.sh"
else
  echo "[!!] no tlc and no installer script found. Install TLA+ manually." >&2
fi

echo "== done =="
