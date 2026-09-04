#!/bin/sh
# skill-kit installer — and updater: safe to re-run any time.
#
#   curl -fsSL https://raw.githubusercontent.com/lutzleonhardt/casefile/main/install.sh | sh
#
# Installs the casefile CLI to ~/.local/bin — nothing else. Installing
# the skills is a deliberate second step: `casefile skills install`.
set -eu

RAW="https://raw.githubusercontent.com/lutzleonhardt/casefile/main"
BIN="$HOME/.local/bin"

mkdir -p "$BIN"
curl -fsSL "$RAW/casefile" -o "$BIN/casefile"
chmod +x "$BIN/casefile"
echo "casefile -> $BIN/casefile"

case ":$PATH:" in
  *":$BIN:"*) ;;
  *) echo "note: $BIN is not on your PATH" ;;
esac

echo "next: casefile skills install   # writes the six skills for the agents found (~/.claude, ~/.codex)"
