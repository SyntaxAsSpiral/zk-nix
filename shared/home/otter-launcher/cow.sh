# Say something as a cow: pick the cow by its preview, then a face.
# Usage: otter-cow [text]   pick a cow, a face, then type the message (no text there keeps the
#                           previewed fortune), then play a tte effect. Text given up front skips
#                           the message step.
#        otter-cow --render cow face   one cow, text from $OTTER_COW_TEXT (fzf preview)
# The face is one of cowsay's modes: borg, dead, greedy, paranoid, stoned, tired, wired,
# youthful. The default face is the cow's own. The last line printed is the command that
# drew the cow, for reference.

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

# shown prints cmd as a nushell command line.
shown() {
  local w out=
  for w in "${cmd[@]}"; do out+="$(nuq "$w") "; done
  printf '%s' "$out"
}

# build sets cmd to the cowsay command for a cow and a face.
build() {
  case $2 in
    borg) flag=(-b) ;;
    dead) flag=(-d) ;;
    greedy) flag=(-g) ;;
    paranoid) flag=(-p) ;;
    stoned) flag=(-s) ;;
    tired) flag=(-t) ;;
    wired) flag=(-w) ;;
    youthful) flag=(-y) ;;
    *) flag=() ;;
  esac
  cmd=(cowsay "${flag[@]}" -f "$1" "$OTTER_COW_TEXT")
}

render() {
  build "$@"
  "${cmd[@]}"
}

if [ "${1:-}" = "--render" ]; then
  render "$2" "${3:-default}"
  exit 0
fi

given=${1:-}
text=$given
[ -n "$text" ] || text=$(fortune -s 2> /dev/null) || text=moo
export OTTER_COW_TEXT=$text

# fzf expands the single-quoted commands, not the shell
# shellcheck disable=SC2016
cow=$(cowsay -l | tail -n +2 | tr ' ' '\n' | sed '/^$/d' | sed 's/\.cow$//' | sort |
  fzf --no-multi \
    --header 'enter picks the cow; the preview says your text, or a fortune' \
    --info-command 'printf " cows ($FZF_POS/$FZF_TOTAL_COUNT)"' \
    --preview 'otter-cow --render {1}' --preview-window 'right,65%,wrap') || exit 0

export GUM_CHOOSE_CURSOR_FOREGROUND=4 GUM_CHOOSE_HEADER_FOREGROUND=8
export GUM_FILTER_INDICATOR_FOREGROUND=4
face=$(gum choose --header 'face' --height 12 \
  default borg dead greedy paranoid stoned tired wired youthful) || exit 0

if [ -z "$given" ]; then
  export GUM_INPUT_HEADER_FOREGROUND=8 GUM_INPUT_CURSOR_FOREGROUND=4
  msg=$(gum input --header 'message' --placeholder 'enter keeps the fortune' --width 0) || exit 0
  [ -z "$msg" ] || OTTER_COW_TEXT=$msg
fi

effect=$(printf '%s\n' none beams binarypath blackhole bouncyballs bubbles burn colorshift crumble \
  decrypt errorcorrect expand fireworks highlight laseretch matrix middleout orbittingvolley \
  overflow pour print rain randomsequence rings scattered slice slide smoke spotlights spray \
  swarm sweep synthgrid thunderstorm unstable vhstape waves wipe |
  gum filter --header 'effect' --placeholder 'type to narrow' --height 12) || exit 0

build "$cow" "$face"
out=$("${cmd[@]}")
line=$(shown)
if [ "$effect" = none ]; then
  printf '%s\n' "$out"
else
  printf '%s\n' "$out" | tte "$effect"
  line="$line| tte $effect"
fi
printf '\n\033[90m%s\033[0m\n' "$line"
