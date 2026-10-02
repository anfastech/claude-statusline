#!/usr/bin/env bash
# Installs the status line script and points ~/.claude/settings.json at it.
set -euo pipefail

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SCRIPT_TARGET="$CLAUDE_DIR/statusline-command.sh"
SETTINGS="$CLAUDE_DIR/settings.json"
RAW_URL="https://raw.githubusercontent.com/anfastech/claude-statusline/main/statusline-command.sh"

command -v jq >/dev/null || { echo "jq is required. Install it: brew install jq (macOS) or apt install jq (Linux)."; exit 1; }
mkdir -p "$CLAUDE_DIR"

# Use the local copy when run from a clone, otherwise download it.
here="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [ -n "$here" ] && [ -f "$here/statusline-command.sh" ]; then
  cp "$here/statusline-command.sh" "$SCRIPT_TARGET"
else
  curl -fsSL "$RAW_URL" -o "$SCRIPT_TARGET"
fi
chmod +x "$SCRIPT_TARGET"
echo "Installed $SCRIPT_TARGET"

[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
backup="$SETTINGS.bak.$(date +%Y%m%d%H%M%S)"
cp "$SETTINGS" "$backup"
echo "Backed up settings to $backup"

tmp="$(mktemp)"
jq --arg cmd "bash $SCRIPT_TARGET" '.statusLine = {type: "command", command: $cmd}' "$SETTINGS" > "$tmp"
mv "$tmp" "$SETTINGS"
echo "Set statusLine in $SETTINGS"
echo "Restart Claude Code to see it."
