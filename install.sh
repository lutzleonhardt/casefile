#!/bin/sh
# skill-kit installer — and updater: safe to re-run any time.
#
#   curl -fsSL https://raw.githubusercontent.com/lutzleonhardt/skill-kit-agentic-workflow/main/install.sh | sh
#
# Installs the casefile CLI to ~/.local/bin and the skills for every
# agent whose config dir exists (~/.claude, ~/.codex).
set -eu

RAW="https://raw.githubusercontent.com/lutzleonhardt/skill-kit-agentic-workflow/main"
BIN="$HOME/.local/bin"

mkdir -p "$BIN"
curl -fsSL "$RAW/casefile" -o "$BIN/casefile"
chmod +x "$BIN/casefile"
echo "casefile -> $BIN/casefile"

case ":$PATH:" in
  *":$BIN:"*) ;;
  *) echo "note: $BIN is not on your PATH" ;;
esac

"$BIN/casefile" skills install
