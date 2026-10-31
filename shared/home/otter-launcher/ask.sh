# Pick a file, type a prompt, and send both to mods. After the answer you can ask a
# follow-up about the same file; esc or an empty line ends it. mods sends to the gateway in
# mods.yml, which caps input near 392000 characters.
if ! command -v mods > /dev/null; then
  echo 'mods is not installed on this host'
  read -rsn1
  exit 0
fi

# fzf expands the single-quoted info and preview commands, not the shell
# shellcheck disable=SC2016
file=$(otter-fd --type f --exclude .git . |
  fzf --header 'pick a file to ask about' \
    --info-command 'printf " files ($FZF_POS/$FZF_TOTAL_COUNT)"' \
    --preview 'bat --color=always --style=numbers --line-range=:200 {}') || exit 0

# ANSI slots for gum, so the terminal palette sets the colours: prompt cyan, cursor blue,
# placeholder bright black.
export GUM_INPUT_PROMPT_FOREGROUND=6 GUM_INPUT_CURSOR_FOREGROUND=4
export GUM_INPUT_PLACEHOLDER_FOREGROUND=8 GUM_INPUT_WIDTH=0

printf '\n  %s\n\n' "$file"
question=$(gum input --placeholder "ask about $(basename "$file")") || exit 0
[ -n "$question" ] || exit 0

mods --format "$question" < "$file"
while question=$(gum input --placeholder 'follow up, or esc to finish') && [ -n "$question" ]; do
  mods --continue-last --format "$question"
done
