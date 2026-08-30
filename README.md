# claude-statusline

A one-line status bar for [Claude Code](https://claude.com/claude-code): where you
are, which model you're on, and how much of the context window you've burned.

```
laptop  |  my-project  |  Opus 5  |  ctx: [███░░░░░░░░░░░░░░░░░] 19% used
```

The context bar is the point. Claude Code tells you the percentage; seeing it as a
bar means you notice you're at 80% before a compaction surprises you mid-task.

## Requirements

- `bash` and [`jq`](https://jqlang.github.io/jq/) on `PATH`
- A terminal font with the block glyphs `█` `░` (most have them; swap the
  characters in the script if yours doesn't)

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/PeterRounce/claude-statusline/main/install.sh | bash
```

Or from a clone:

```sh
git clone https://github.com/PeterRounce/claude-statusline.git
cd claude-statusline
./install.sh
```

The installer copies `statusline.sh` to `~/.claude/statusline.sh` and adds the
`statusLine` block to `~/.claude/settings.json`, keeping every other setting
intact. Anything it replaces is backed up next to the original with a
`.bak.<timestamp>` suffix. Restart Claude Code to pick it up.

### Manual install

Copy `statusline.sh` wherever you like, `chmod +x` it, and add this to
`~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh",
    "padding": 0
  }
}
```

`padding: 0` runs the line edge-to-edge with no left margin. Drop it if you
prefer the default indent.

## How it works

Claude Code pipes a JSON blob of session state into the command on **stdin**
every time the bar refreshes, and whatever the command writes to **stdout**
becomes the bar. That's the whole contract — the script is just `jq` plus some
string building.

The three fields this one reads:

| Field | Used for |
| --- | --- |
| `.model.display_name` | `Opus 5` |
| `.workspace.current_dir` (falls back to `.cwd`) | basename → `my-project` |
| `.context_window.used_percentage` | the bar and the `19%` |

To see the full payload, drop `cat > /tmp/statusline-input.json` at the top of
the script and open that file after a refresh.

## Customising

Everything worth changing is in the last dozen lines of `statusline.sh`.

**Bar width** — `BAR_WIDTH=20`. A 10-cell bar reads fine on a narrow terminal.

**Different characters** — replace `█` and `░`, e.g. `=` and `-`, or `▓`/`▒`.

**Drop the hostname** — useful if you're never SSH'd anywhere. Edit the last
line to:

```bash
printf "%s  |  %s  |  ctx: %s" "$dir_label" "$model" "$context_str"
```

**Colour** — ANSI escapes work. To turn the bar red past 80%:

```bash
color=$'\033[32m'
[ "$pct_int" -ge 60 ] && color=$'\033[33m'
[ "$pct_int" -ge 80 ] && color=$'\033[31m'
context_str="${color}[${bar}] ${pct_int}% used"$'\033[0m'
```

**Git branch** — the payload doesn't carry one, so shell out for it:

```bash
branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
[ -n "$branch" ] && dir_label="$dir_label ($branch)"
```

Keep additions cheap. The script runs on every refresh, so anything slow (a
network call, a big `find`) will make the whole bar feel laggy.

## Troubleshooting

**Bar is blank or shows an error** — run the script by hand with a fake payload:

```sh
echo '{"model":{"display_name":"Opus 5"},"workspace":{"current_dir":"/tmp/demo"},"context_window":{"used_percentage":42}}' \
  | ~/.claude/statusline.sh
```

**`jq not found`** — `brew install jq` on macOS, `sudo apt install jq` on Debian
or Ubuntu.

**Nothing changed** — restart Claude Code, and check `~/.claude/settings.json`
is valid JSON (`jq empty ~/.claude/settings.json`).

## Uninstall

```sh
jq 'del(.statusLine)' ~/.claude/settings.json > /tmp/s.json && mv /tmp/s.json ~/.claude/settings.json
rm ~/.claude/statusline.sh
```

## License

MIT
