# The otter front door: the NixOS logo beside four lines. LOGO and ALCHEMY are set by otter-launcher.nix.
esc=$'\e'

logo=$(chafa --size=22x10 --fg-only --symbols=block+border+space --colors=full "$LOGO" | sed 's/\x1b\[?25[lh]//g')

hour=$((10#$(date +%H)))
if   [ "$hour" -lt 7 ];  then sun="🌄"
elif [ "$hour" -lt 12 ]; then sun="🌇"
elif [ "$hour" -lt 18 ]; then sun="🌆"
elif [ "$hour" -lt 22 ]; then sun="🌃"
else                          sun="🌉"
fi

# One dot per mesh host: lit when tailscale does not call it offline.
status=$(tailscale status 2>/dev/null || true)
mesh=""
for host in adeck nxiz zrrh tm20 seed quita; do
  if printf '%s\n' "$status" | grep -E "^[0-9.]+ +$host " | grep -q offline; then
    mesh+="${esc}[90m○${esc}[0m $host  "
  else
    mesh+="${esc}[32m●${esc}[0m $host  "
  fi
done

# Chronohex: the last six hex digits of the clock in nanoseconds, with its alchemical glyph and gloss.
hex=$(printf '%x' "$(date +%s%N)")
hex=${hex: -6}
idx=$((0x$hex % 116))
glyph=$(printf '%b' "$(printf '\\U%08x' $((0x1F700 + idx)))")
gloss=$(sed -n "$((idx + 1))p" "$ALCHEMY")

info=(
  "${esc}[1m${USER}@${HOSTNAME}${esc}[0m"
  "$sun  $(date '+%a %d %b · %H:%M')"
  "$mesh"
  "${esc}[35m${hex}${esc}[0m $glyph ${esc}[90m(${gloss})${esc}[0m"
)

row=0
while IFS= read -r line; do
  plain=$(printf '%s' "$line" | sed 's/\x1b\[[0-9;]*m//g')
  pad=$((26 - ${#plain}))
  [ "$pad" -lt 1 ] && pad=1
  printf '%s%s%*s' "$line" "${esc}[0m" "$pad" ""
  i=$((row - 3))
  if [ "$i" -ge 0 ] && [ "$i" -lt "${#info[@]}" ]; then
    printf '%s' "${info[$i]}"
  fi
  row=$((row + 1))
  printf '\n'
done <<< "$logo"
