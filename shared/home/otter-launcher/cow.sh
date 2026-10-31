# Say something as a cow: pick the cow by its preview, then a face.
# Usage: otter-cow [text]   no text uses a short fortune
#        otter-cow --render cow face   one cow, text from $OTTER_COW_TEXT (fzf preview)
# COWS is set by otter-launcher.nix. The face is one of cowsay's modes: borg, dead, greedy,
# paranoid, stoned, tired, wired, youthful. The default face is the cow's own.

render() {
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
  cowsay "${flag[@]}" -f "$COWS/$1.cow" "$OTTER_COW_TEXT"
}

if [ "${1:-}" = "--render" ]; then
  render "$2" "${3:-default}"
  exit 0
fi

text=${1:-}
[ -n "$text" ] || text=$(fortune -s 2> /dev/null) || text=moo
export OTTER_COW_TEXT=$text

# fzf expands the single-quoted commands, not the shell
# shellcheck disable=SC2016
cow=$(cowsay -l | tail -n +2 | tr ' ' '\n' | sed '/^$/d' | sed 's/\.cow$//' | sort |
  fzf --height=50% --min-height=18 --no-multi \
    --header 'enter picks the cow; the preview says your text' \
    --info-command 'printf " cows ($FZF_POS/$FZF_TOTAL_COUNT)"' \
    --preview 'otter-cow --render {1}' --preview-window 'right,65%,wrap') || exit 0

export GUM_CHOOSE_CURSOR_FOREGROUND=4 GUM_CHOOSE_HEADER_FOREGROUND=8
face=$(gum choose --header 'face' --height 12 \
  default borg dead greedy paranoid stoned tired wired youthful) || exit 0

render "$cow" "$face"
