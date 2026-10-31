# The otter header: the saved logo (4 rows) beside name, rule, date and time. LOGO_ANSI is set
# by otter-launcher.nix. The art is chafa output of assets/nix-logo-work/nix-logo-solid-tight.png
# (--format=symbols --size=9x4 --fg-only --symbols=block+border+space --colors=full), with each
# of its six Mocha colours mapped to the nearest slot of the kitty Mocha palette.
esc=$'\e'

# ANSI palette slots, so the terminal theme sets the colours. Each is the nearest slot of the
# official Catppuccin Mocha kitty palette to the Mocha colour it replaces.
lavender="${esc}[34m" peach="${esc}[31m" yellow="${esc}[33m" dim="${esc}[90m" off="${esc}[0m"

# Time of day: sunrise, day, sunset or night, as the glyph beside the time.
hour=$((10#$(date +%H)))
if [ "$hour" -ge 7 ] && [ "$hour" -lt 18 ]; then
  tod="🌞"
elif [ "$hour" -eq 5 ] || [ "$hour" -eq 6 ]; then
  tod="🌅"
elif [ "$hour" -eq 18 ]; then
  tod="🌇"
else
  tod="🌃"
fi

# Signs of the sun and the moon from sideriod's gnomon on adeck, cached for 30 minutes so the
# launcher never waits on the network. Failing that, the sun sign comes from the calendar and
# the moon sign is left out (it needs an ephemeris).
cache="${XDG_CACHE_HOME:-$HOME/.cache}/otter-launcher/sky"
sun="" moon="" elong=""
if [ -r "$cache" ] && [ $(($(date +%s) - $(stat -c %Y "$cache"))) -lt 1800 ]; then
  read -r sun moon elong < "$cache" || true
else
  for url in http://127.0.0.1:8878 http://adeck:8878; do
    if json=$(curl -sf -m 1 "$url/api/chart?kind=sky"); then
      sun=$(jq -r '.positions.Sun.sign' <<< "$json")
      moon=$(jq -r '.positions.Moon.sign' <<< "$json")
      elong=$(jq -r '((.positions.Moon.longitude_deg - .positions.Sun.longitude_deg) % 360 + 360) % 360' <<< "$json")
      break
    fi
  done
  mkdir -p "${cache%/*}"
  if [ -n "$sun" ]; then
    echo "$sun $moon $elong" > "$cache"
  else
    : > "$cache" # remember the failure for 30 minutes
  fi
fi
if [ -z "$sun" ]; then
  md=$((10#$(date +%m%d)))
  signs=(Capricorn Aquarius Pisces Aries Taurus Gemini Cancer Leo Virgo Libra Scorpio Sagittarius Capricorn)
  starts=(0 120 219 321 420 521 621 723 823 923 1023 1122 1222)
  for i in "${!starts[@]}"; do [ "$md" -ge "${starts[i]}" ] && sun=${signs[i]}; done
fi
# Moon phase: the elongation of the moon from the sun in eighths of a circle. Without sideriod,
# the synodic month (29.53059 days) counted from the new moon of 2000-01-06 18:14 UTC stands in,
# accurate to hours, which is plenty for eight phases.
if [ -z "$elong" ]; then
  elong=$(awk -v now="$(date +%s)" 'BEGIN { s = 29.530588861; print (((now - 947182440) / 86400) % s) / s * 360 }')
fi
phases=(🌑 🌒 🌓 🌔 🌕 🌖 🌗 🌘)
phase=${phases[$(awk -v e="$elong" 'BEGIN { print int(e / 45 + 0.5) % 8 }')]}
# The glyph beside the time: by day the sun's, at night the moon's phase, each with its sign.
if [ "$tod" = "🌃" ]; then
  tod=$phase sign=$moon
else
  sign=$sun
fi

mapfile -t logo < "$LOGO_ANSI"

# Nerd font icons: calendar, clock. Four lines beside four logo rows.
info=(
  "${lavender}${esc}[1m🐚 Z Shell${off}"
  "${dim}────────────────────${off}"
  "${peach}  $(date '+%a %d %b')${off}"
  "${yellow}  $(date '+%H:%M') $tod${sign:+ $sign}${off}"
)
for i in 0 1 2 3; do
  printf '%s  %s\n' "${logo[i]}" "${info[i]:-}"
done

# A blank line of padding under the logo, then a braille wave under the header: the dots step down and up inside the row, and each step takes
# the next ANSI slot (red, yellow, green, teal, blue, pink), so the terminal palette colours it.
printf '\n'
cols=$({ stty size </dev/tty; } 2>/dev/null | cut -d' ' -f2)
wave=(⣀ ⠤ ⠒ ⠉ ⠒ ⠤)
slot=(31 33 32 36 34 35)
rule=""
for ((i = 0; i < ${cols:-80} - 2; i++)); do rule+="${esc}[${slot[i % 6]}m${wave[i % 6]}"; done
printf '%s%s\n' "$rule" "$off"
