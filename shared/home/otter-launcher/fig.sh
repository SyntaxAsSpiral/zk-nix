# Render text in a figlet or toilet font: look at every font, pick filters, play an effect.
# Usage: otter-fig [text]              pick a font by its preview, then filters, then an effect
#        otter-fig --render font [filter...]   one font, text from $OTTER_FIG_TEXT (fzf preview)
# A font is f:name (figlet's own) or t:name (toilet's). toilet draws both, and its filters
# colour with ANSI palette slots. FIGLET_FONTS and TOILET_FONTS are set by otter-launcher.nix.

render() {
  tag=${1%%:*} name=${1#*:}
  shift
  if [ "$tag" = f ]; then dir=$FIGLET_FONTS; else dir=$TOILET_FONTS; fi
  args=()
  if [ $# -gt 0 ]; then
    filters=$(IFS=:; echo "$*")
    args=(-F "$filters")
  fi
  toilet -d "$dir" -f "$name" -w "${FZF_PREVIEW_COLUMNS:-${COLUMNS:-80}}" "${args[@]}" -- "$OTTER_FIG_TEXT"
}

if [ "${1:-}" = "--render" ]; then
  shift
  render "$@"
  exit 0
fi

text=${1:-}
if [ -z "$text" ]; then
  text=$(gum input --placeholder 'text to render') || exit 0
fi
[ -n "$text" ] || exit 0
export OTTER_FIG_TEXT=$text

fonts() {
  for f in "$FIGLET_FONTS"/*.flf; do
    n=$(basename "$f" .flf)
    printf 'f:%s\tfiglet  %s\n' "$n" "$n"
  done
  for f in "$TOILET_FONTS"/*.tlf; do
    n=$(basename "$f" .tlf)
    printf 't:%s\ttoilet  %s\n' "$n" "$n"
  done
}

# fzf expands the single-quoted commands, not the shell
# shellcheck disable=SC2016
font=$(fonts | fzf --height=50% --min-height=18 --delimiter '\t' --with-nth 2.. --no-multi \
  --header 'enter picks the font; the preview draws your text in it' \
  --info-command 'printf " fonts ($FZF_POS/$FZF_TOTAL_COUNT)"' \
  --preview 'otter-fig --render {1}' --preview-window 'right,65%,wrap') || exit 0
font=${font%%$'\t'*}

export GUM_CHOOSE_CURSOR_FOREGROUND=4 GUM_CHOOSE_HEADER_FOREGROUND=8
export GUM_CHOOSE_SELECTED_FOREGROUND=5 GUM_FILTER_INDICATOR_FOREGROUND=4
filters=()
mapfile -t filters < <(gum choose --no-limit --header 'filters: space toggles, enter applies, none is fine' \
  crop gay metal border flip flop 180 left right) || exit 0

effect=$(printf '%s\n' none beams binarypath blackhole bouncyballs bubbles burn colorshift crumble \
  decrypt errorcorrect expand fireworks highlight laseretch matrix middleout orbittingvolley \
  overflow pour print rain randomsequence rings scattered slice slide smoke spotlights spray \
  swarm sweep synthgrid thunderstorm unstable vhstape waves wipe |
  gum filter --header 'effect' --placeholder 'type to narrow' --height 12) || exit 0

out=$(render "$font" "${filters[@]}")
if [ "$effect" = none ]; then
  printf '%s\n' "$out"
else
  printf '%s\n' "$out" | tte "$effect"
fi
