# Write text in an esoteric script: look at every script, then keep one.
# Usage: otter-eso [text]            pick a script by its preview; the text drawn in it is printed
#        otter-eso --render script   one script, text from $OTTER_ESO_TEXT (fzf preview)
# The scripts are those of the esoscript command. Aurebesh, maya, tengwar, quenya and klingon
# need the fonts of assets/esofonts on the machine that draws the terminal. The last line
# printed is the command that drew the text, for reference.

# nuq quotes one word so nushell reads it back unchanged: bare when safe, single quotes
# for plain text, escaped double quotes when it holds an apostrophe, a quote or a control.
nuq() {
  local s=$1
  if [[ $s =~ ^[A-Za-z0-9_./:=+-]+$ ]]; then
    printf '%s' "$s"
  elif [[ $s != *[\'\"\\$'\n\t\r']* ]]; then
    printf "'%s'" "$s"
  else
    s=${s//\\/\\\\}
    s=${s//\"/\\\"}
    s=${s//$'\n'/\\n}
    s=${s//$'\t'/\\t}
    s=${s//$'\r'/\\r}
    printf '"%s"' "$s"
  fi
}

if [ "${1:-}" = "--render" ]; then
  if [ "$2" = all ]; then
    esoscript --all "$OTTER_ESO_TEXT"
  else
    esoscript -s "$2" "$OTTER_ESO_TEXT"
    font=$(esoscript --list | awk -F'\t' -v s="$2" '$1 == s { print $2 }')
    [ -z "$font" ] || printf '\n\033[90mfont: %s\033[0m\n' "$font"
  fi
  exit 0
fi

text=${1:-}
if [ -z "$text" ]; then
  export GUM_INPUT_HEADER_FOREGROUND=8 GUM_INPUT_CURSOR_FOREGROUND=4
  text=$(gum input --header 'text' --placeholder 'text to write' --width 0) || exit 0
fi
[ -n "$text" ] || exit 0
export OTTER_ESO_TEXT=$text

# fzf expands the single-quoted commands, not the shell
# shellcheck disable=SC2016
pick=$({ printf 'all\tevery script at once\n'; esoscript --list; } |
  fzf --no-multi --delimiter '\t' --with-nth 1 \
    --header 'enter keeps the script; the preview writes your text in it' \
    --info-command 'printf " scripts ($FZF_POS/$FZF_TOTAL_COUNT)"' \
    --preview 'otter-eso --render {1}' --preview-window 'right,65%,wrap') || exit 0
script=${pick%%$'\t'*}

if [ "$script" = all ]; then
  esoscript --all "$text"
  line="esoscript --all $(nuq "$text")"
else
  esoscript -s "$script" "$text"
  line="esoscript -s $script $(nuq "$text")"
fi
printf '\n\033[90m%s\033[0m\n' "$line"
