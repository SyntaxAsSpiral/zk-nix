# The otter header: the saved logo (4 rows) beside name, rule, date and time. LOGO_ANSI is set
# by otter-launcher.nix. The art is chafa output of assets/nix-logo-work/nix-logo-solid-tight.png
# (--format=symbols --size=9x4 --fg-only --symbols=block+border+space --colors=full), with each
# of its six Mocha colours mapped to the nearest slot of the kitty Mocha palette.
esc=$'\e'

# ANSI palette slots, so the terminal theme sets the colours. Each is the nearest slot of the
# official Catppuccin Mocha kitty palette to the Mocha colour it replaces.
lavender="${esc}[34m" peach="${esc}[31m" yellow="${esc}[33m" dim="${esc}[90m" off="${esc}[0m"

hour=$((10#$(date +%H)))
if [ "$hour" -lt 7 ]; then
  sun="🌄"
elif [ "$hour" -lt 12 ]; then
  sun="🌇"
elif [ "$hour" -lt 18 ]; then
  sun="🌆"
elif [ "$hour" -lt 22 ]; then
  sun="🌃"
else
  sun="🌉"
fi

mapfile -t logo < "$LOGO_ANSI"

# Nerd font icons: calendar, clock. Four lines beside four logo rows.
info=(
  "${lavender}${esc}[1m🐚 Z Shell${off}"
  "${dim}────────────────────${off}"
  "${peach}  $(date '+%a %d %b')${off}"
  "${yellow}  $(date '+%H:%M') $sun${off}"
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
