# The otter header: the saved logo (rows 0-4) beside name, date and time. Row 5 of the
# logo rides on the prompt line, see prompt_sign in config.toml. LOGO_ANSI is set by
# otter-launcher.nix. The art is chafa output (--format=symbols --size=14x6 --fg-only
# --symbols=block+border+space --colors=full) with each truecolor mapped to its nearest palette slot.
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

# Nerd font icons: calendar, clock. Four lines beside five logo rows; the last row stands alone.
info=(
  "${lavender}${esc}[1m🐚 Z Shell${off}"
  "${dim}────────────────────${off}"
  "${peach}  $(date '+%a %d %b')${off}"
  "${yellow}  $(date '+%H:%M') $sun${off}"
)
for i in 0 1 2 3 4; do
  printf '%s  %s\n' "${logo[i]}" "${info[i]:-}"
done
