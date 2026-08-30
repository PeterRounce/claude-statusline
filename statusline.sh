#!/usr/bin/env bash
# Claude Code status line: host | dir | model | context bar
# Docs: https://github.com/PeterRounce/claude-statusline

if ! command -v jq >/dev/null 2>&1; then
  printf "statusline: jq not found (install jq: brew install jq / apt install jq)"
  exit 0
fi

input=$(cat)

IFS=$'\t' read -r model cwd used_pct < <(
  echo "$input" | jq -r '[
    .model.display_name // "",
    .workspace.current_dir // .cwd // "",
    (.context_window.used_percentage // "" | tostring)
  ] | @tsv'
)

dir_label="${cwd##*/}"

BAR_WIDTH=20
if [ -n "$used_pct" ]; then
  # Integer rounding with pure bash (strip decimal, add 0.5 trick)
  pct_int=${used_pct%%.*}
  dec=${used_pct#*.}
  [ "$dec" != "$used_pct" ] && [ "${dec:0:1}" -ge 5 ] 2>/dev/null && pct_int=$((pct_int + 1))
else
  pct_int=0
fi

filled=$((pct_int * BAR_WIDTH / 100))
empty=$((BAR_WIDTH - filled))

bar=""
for ((i=0; i<filled; i++)); do bar+="█"; done
for ((i=0; i<empty; i++)); do bar+="░"; done

context_str="[${bar}] ${pct_int}% used"

printf "%s  |  %s  |  %s  |  ctx: %s" "$HOSTNAME" "$dir_label" "$model" "$context_str"
