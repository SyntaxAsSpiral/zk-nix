# Choose an eikon avatar and play it: one from the public catalog or a local .eikon file.
# Usage: otter-ek [name|path]   no argument: pick by poster from the catalog and the local
#                               eikons; a catalog name or a .eikon path plays it at once
#        otter-ek --render kind key          the poster of one list item (fzf preview)
#        otter-ek --frames file signal [n]   print the first n frames (default 1) that play
#                                            for a signal, each under a "-- clip index" line
# Keys while playing: i idle, l listening, t thinking, s speaking, w working, e error,
# space holds the frame (reduced motion), q quits.
# A signal resolves through the header's signals map and its fallback chain, then
# defaultSignal. A clip's loopFrom follows the eikon SPEC: absent or 0 loops it all,
# 0 < N < count plays the intro once and loops from N, N == count holds the last frame.
# A clip colour of ansi:N tints with the terminal palette, #rrggbb with truecolor.
# Catalog runtimes are checked against their sha256 digest and cached. Local eikons live in
# $XDG_DATA_HOME/eikons and herm's eikons directory. The last line printed is the command.

CATALOG=https://eikon.liftaris.dev/eikons
CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/otter-ek
LOCAL_DIRS=("${XDG_DATA_HOME:-$HOME/.local/share}/eikons"
  "${HERM_CONFIG_DIR:-${HERMES_HOME:-$HOME/.hermes}/herm}/eikons")
US=$'\x1e' RS=$'\x1f'
mkdir -p "$CACHE"

# catalog prints the catalog JSON, fetched again once a day; a failed fetch keeps the old one.
catalog() {
  local f=$CACHE/catalog.json
  if [ ! -s "$f" ] || [ -n "$(find "$f" -mmin +1440 2> /dev/null)" ]; then
    if curl -fsSL --max-time 10 "$CATALOG" -o "$f.tmp" && jq -e 'type == "array"' "$f.tmp" > /dev/null; then
      mv "$f.tmp" "$f"
    else
      rm -f "$f.tmp"
    fi
  fi
  if [ -s "$f" ]; then cat "$f"; else echo '[]'; fi
}

# fetch prints the cached path of a catalog eikon's runtime, downloading and checking it first.
fetch() {
  local row url digest out
  row=$(catalog | jq -r --arg n "$1" 'map(select(.name == $n))[0] // empty | "\(.runtimeUrl)\t\(.trust.runtimeDigest // "")"')
  [ -n "$row" ] || { echo "otter-ek: no eikon named $1 in the catalog" >&2; return 1; }
  url=${row%%$'\t'*} digest=${row#*$'\t'}
  digest=${digest#sha256:}
  out=$CACHE/${digest:-$1}.eikon
  if [ ! -s "$out" ]; then
    curl -fsSL --max-time 60 "$url" -o "$out.tmp" || { rm -f "$out.tmp"; return 1; }
    if [ -n "$digest" ] && [ "$(sha256sum < "$out.tmp" | cut -d' ' -f1)" != "$digest" ]; then
      rm -f "$out.tmp"
      echo "otter-ek: $1 does not match its catalog digest; not playing it" >&2
      return 1
    fi
    mv "$out.tmp" "$out"
  fi
  printf '%s\n' "$out"
}

# decode prints an eikon's NDJSON, gunzipping it when the bytes are gzip.
decode() {
  if [ "$(head -c 2 "$1" | od -An -tx1 | tr -d ' \n')" = 1f8b ]; then gzip -dc "$1"; else cat "$1"; fi
}

# load reads an eikon into the globals below in one jq pass.
declare -A FRAME FCOLOR CLIPN CLIPFPS CLIPLOOP CLIPCOLOR SIGCLIP SIGFALL
CLIPS=() TITLE='' DEFAULT=state.idle ROWS=24 COLS=48
load() {
  local kind a b c d
  while IFS=$US read -r kind a b c d; do
    case $kind in
      H) TITLE=$a DEFAULT=$b COLS=$c ROWS=$d ;;
      S) SIGCLIP[$a]=$b SIGFALL[$a]=$c ;;
      C) CLIPS+=("$a") CLIPFPS[$a]=$b CLIPLOOP[$a]=$c CLIPCOLOR[$a]=$d CLIPN[$a]=0 ;;
      F)
        FRAME[$a:$b]=$c FCOLOR[$a:$b]=$d
        if [ "$((b + 1))" -gt "${CLIPN[$a]:-0}" ]; then CLIPN[$a]=$((b + 1)); fi
        ;;
    esac
  done < <(decode "$1" | jq -r --arg u "$US" --arg r "$RS" '
    if .type == "header" then
      (["H", (.title // .id // ""), (.defaultSignal // "state.idle"), (.size.cols // 48), (.size.rows // 24)] | map(tostring) | join($u)),
      (.signals // {} | to_entries[] | ["S", .key, (.value.clip // ""), (.value.fallback // "")] | join($u))
    elif .type == "clip" then
      ["C", .name, (.fps // 16), (.loopFrom // 0), (.color // "")] | map(tostring) | join($u)
    elif .type == "frame" then
      ["F", .clip, .index, (.rows | join($r)), (.color // "")] | map(tostring) | join($u)
    else empty end')
  [ "${#CLIPS[@]}" -gt 0 ] || { echo "otter-ek: $1 holds no clips" >&2; return 1; }
}

# resolve prints the clip a signal plays: its mapping, then its fallbacks, then defaultSignal,
# then the first clip.
resolve() {
  local sig=$1 hops=0 clip
  while [ "$hops" -lt 12 ] && [ -n "$sig" ]; do
    clip=${SIGCLIP[$sig]-}
    if [ -n "$clip" ] && [ "${CLIPN[$clip]:-0}" -gt 0 ]; then
      printf '%s\n' "$clip"
      return 0
    fi
    if [ -n "${SIGFALL[$sig]-}" ]; then sig=${SIGFALL[$sig]}
    elif [ "$sig" != "$DEFAULT" ]; then sig=$DEFAULT
    else sig=
    fi
    hops=$((hops + 1))
  done
  if [ "${CLIPN[$1]:-0}" -gt 0 ]; then printf '%s\n' "$1"; else printf '%s\n' "${CLIPS[0]}"; fi
}

# index prints the frame a clip shows at tick t (eikon's player/model.ts frameIndex).
index() {
  local clip=$1 t=$2 n=${CLIPN[$1]} lf=${CLIPLOOP[$1]:-0} start
  if [ "$t" -lt "$n" ]; then echo "$t"; return 0; fi
  if [ "$lf" -ge "$n" ]; then echo "$((n - 1))"; return 0; fi
  start=$((lf < 0 ? 0 : lf))
  echo "$((start + (t - start) % (n - start)))"
}

# fg prints the escape for a colour: ansi:N is terminal palette slot N (0-15, so it follows the
# theme), #rrggbb is truecolor. Anything else prints nothing.
fg() {
  local h=${1#\#}
  if [[ $1 =~ ^ansi:(1[0-5]|[0-9])$ ]]; then
    local n=${BASH_REMATCH[1]}
    if [ "$n" -lt 8 ]; then printf '\033[%dm' "$((30 + n))"; else printf '\033[%dm' "$((82 + n))"; fi
  elif [[ $h =~ ^[0-9a-fA-F]{6}$ ]]; then
    printf '\033[38;2;%d;%d;%dm' "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}"
  fi
}

if [ "${1:-}" = --frames ]; then
  load "$2"
  clip=$(resolve "$3")
  for ((t = 0; t < ${4:-1}; t++)); do
    i=$(index "$clip" "$t")
    printf -- '-- %s %s\n' "$clip" "$i"
    printf '%s\n' "${FRAME[$clip:$i]//$RS/$'\n'}"
  done
  exit 0
fi

if [ "${1:-}" = --render ]; then
  if [ "$2" = c ]; then
    catalog | jq -r --arg n "$3" 'map(select(.name == $n))[0] // {} |
      "\(.glyph // "") \(.title // .name)  by \(.author // "?")  v\(.version // "?")\n", (.poster // "")'
  else
    load "$3"
    clip=$(resolve "$DEFAULT")
    printf '%s  %s\n\n%s\n' "$TITLE" "$3" "${FRAME[$clip:0]//$RS/$'\n'}"
  fi
  exit 0
fi

# Choose: an argument names a file or a catalog eikon; otherwise pick from both lists.
arg=${1:-}
if [ -n "$arg" ] && [ -f "$arg" ]; then
  kind=l key=$(realpath "$arg")
elif [ -n "$arg" ]; then
  kind=c key=$arg
else
  # fzf expands the single-quoted commands, not the shell
  # shellcheck disable=SC2016
  sel=$({
    catalog | jq -r '.[] | "c\t\(.name)\t\(.glyph // " ") \(.name)  \u001b[90mcatalog · \(.author // "?")\u001b[0m"'
    for d in "${LOCAL_DIRS[@]}"; do
      if [ -d "$d" ]; then find "$d" -name '*.eikon' -type f 2> /dev/null; fi
    done | sort -u | while read -r f; do printf 'l\t%s\t◇ %s  \033[90mlocal · %s\033[0m\n' "$f" "$(basename "$f" .eikon)" "$f"; done
  } | fzf --ansi --no-multi --delimiter '\t' --with-nth 3 \
    --header 'enter plays it; keys then: i l t s w e switch state, space holds, q quits' \
    --info-command 'printf " eikons ($FZF_POS/$FZF_TOTAL_COUNT)"' \
    --preview 'otter-ek --render {1} {2}' --preview-window 'right,52,nowrap') || exit 0
  IFS=$'\t' read -r kind key _ <<< "$sel"
fi

if [ "$kind" = c ]; then file=$(fetch "$key") || exit 1; else file=$key; fi
load "$file"

# Play in the alternate screen, centred, until q. read -t is the frame clock and the keyboard.
restore() { printf '\033[0m\033[?25h\033[?1049l'; stty sane < /dev/tty 2> /dev/null || true; }
trap restore EXIT
trap 'exit 130' INT TERM
place() {
  local h w
  read -r h w < <(stty size < /dev/tty)
  top=$(((h - ROWS - 2) / 2 + 1)) left=$(((w - COLS) / 2 + 1))
  [ "$top" -ge 1 ] || top=1
  [ "$left" -ge 1 ] || left=1
  printf '\033[2J'
}
trap place WINCH
printf '\033[?1049h\033[?25l'
place

now() { local t=${EPOCHREALTIME/[.,]/}; echo "$((10#$t / 1000))"; }
sig=$DEFAULT held=0
clip=$(resolve "$sig") t0=$(now) hold_ms=0
while :; do
  fps=${CLIPFPS[$clip]:-16} fps=${fps%.*}; [ "${fps:-0}" -ge 1 ] || fps=16
  if [ "$held" = 1 ]; then ms=$hold_ms; else ms=$(($(now) - t0)); fi
  i=$(index "$clip" "$((ms * fps / 1000))")
  colour=$(fg "${FCOLOR[$clip:$i]:-${CLIPCOLOR[$clip]-}}")
  out=$colour r=0
  frame=${FRAME[$clip:$i]-}
  while IFS= read -r -d "$RS" row; do
    printf -v seg '\033[%d;%dH%s' "$((top + r))" "$left" "$row"
    out+=$seg
    r=$((r + 1))
  done <<< "$frame$RS"
  state=$sig
  [ "$held" = 0 ] || state="$sig (held)"
  printf -v seg '\033[0m\033[%d;%dH\033[2K\033[90m%s · %s → %s %s/%s · i l t s w e · space · q\033[0m' \
    "$((top + ROWS + 1))" "$left" "$TITLE" "$state" "$clip" "$i" "${CLIPN[$clip]}"
  out+=$seg
  printf '%s' "$out"
  k=
  IFS= read -rsn1 -t "$(printf '0.%03d' "$((1000 / fps))")" k < /dev/tty || k=
  case $k in
    q | Q) break ;;
    ' ')
      if [ "$held" = 0 ]; then held=1 hold_ms=$ms; else held=0 t0=$(($(now) - hold_ms)); fi
      ;;
    i | l | t | s | w | e)
      case $k in
        i) sig=state.idle ;; l) sig=state.listening ;; t) sig=state.thinking ;;
        s) sig=state.speaking ;; w) sig=state.working ;; e) sig=state.error ;;
      esac
      clip=$(resolve "$sig") t0=$(now) held=0 hold_ms=0
      printf '\033[2J'
      ;;
  esac
done
restore
trap - EXIT
if [ "$kind" = c ]; then printf '\033[90motter-ek %s\033[0m\n' "$key"; else printf '\033[90motter-ek %q\033[0m\n' "$key"; fi
