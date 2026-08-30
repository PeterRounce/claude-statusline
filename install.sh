#!/usr/bin/env bash
# Installs the status line into your Claude Code config.
#
#   ./install.sh                                  # from a clone
#   curl -fsSL https://raw.githubusercontent.com/PeterRounce/claude-statusline/main/install.sh | bash
#
# Backs up anything it replaces. Re-running is safe.

set -euo pipefail

RAW_URL="https://raw.githubusercontent.com/PeterRounce/claude-statusline/main/statusline.sh"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SETTINGS="$CLAUDE_DIR/settings.json"
TARGET="$CLAUDE_DIR/statusline.sh"
STAMP="$(date +%Y%m%d%H%M%S)"

command -v jq >/dev/null 2>&1 || {
  echo "error: jq is required (brew install jq  /  sudo apt install jq)" >&2
  exit 1
}

mkdir -p "$CLAUDE_DIR"

# --- the script ------------------------------------------------------------
# Only trust a sibling statusline.sh when this script is genuinely running from
# a file - piping into bash leaves BASH_SOURCE empty, and $PWD could hold
# anything.
src=""
self="${BASH_SOURCE[0]:-}"
if [ -n "$self" ] && [ -f "$self" ]; then
  candidate="$(cd "$(dirname "$self")" && pwd)/statusline.sh"
  [ -f "$candidate" ] && src="$candidate"
fi

if [ -n "$src" ]; then
  fetched=""
else
  fetched="$(mktemp)"; trap 'rm -f "$fetched"' EXIT
  echo "fetching statusline.sh ..."
  curl -fsSL "$RAW_URL" -o "$fetched"
  src="$fetched"
fi

if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
  mv "$TARGET" "$TARGET.bak.$STAMP"
  echo "backed up existing script -> $TARGET.bak.$STAMP"
fi
install -m 0755 "$src" "$TARGET"
echo "installed $TARGET"

# --- settings.json ---------------------------------------------------------
if [ -f "$SETTINGS" ]; then
  jq empty "$SETTINGS" 2>/dev/null || {
    echo "error: $SETTINGS is not valid JSON - fix it, then re-run" >&2
    exit 1
  }
  cp "$SETTINGS" "$SETTINGS.bak.$STAMP"
  echo "backed up settings   -> $SETTINGS.bak.$STAMP"
else
  echo '{}' > "$SETTINGS"
fi

# Prefer the ~-relative form so the config stays portable across machines.
cmd="$TARGET"
case "$cmd" in "$HOME"/*) cmd="~${cmd#"$HOME"}" ;; esac

tmp="$(mktemp)"
jq --arg cmd "$cmd" \
   '.statusLine = {type: "command", command: $cmd, padding: 0}' \
   "$SETTINGS" > "$tmp"
mv "$tmp" "$SETTINGS"

echo "wired statusLine -> $cmd"
echo
echo "Preview:"
printf '  '
echo '{"model":{"display_name":"Opus 5"},"workspace":{"current_dir":"'"$PWD"'"},"context_window":{"used_percentage":18.6}}' \
  | "$TARGET"
echo
echo
echo "Restart Claude Code (or run /statusline) to pick it up."
