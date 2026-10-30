# Explore a JSON file with jq as you type: pick a file, then edit the filter and watch the result.
# Enter opens the result in less.
# Usage: otter-jq [file]          start with this file, or pick one
f=${1:-}
if [ -z "$f" ]; then
  # shellcheck disable=SC2016
  f=$(otter-fd --type f --extension json --exclude .git . |
    fzf --info-command 'printf " json files ($FZF_POS/$FZF_TOTAL_COUNT)"' \
      --preview 'jq -C . {} 2>&1 | head -n 200') || exit 0
fi
export f

# fzf expands the single-quoted commands, not the shell
# shellcheck disable=SC2016
q=$(echo | fzf --disabled --print-query --query . \
  --header "$f  type a jq filter, enter opens the result" \
  --info-command 'printf " jq filter"' \
  --preview 'jq -C {q} "$f" 2>&1' --preview-window 'down,80%,wrap' | head -n 1) || exit 0
jq -C "$q" "$f" | less -R
