# The otter header: the saved logo (rows 0-4) beside name, host, date and time. Row 5 of the
# logo rides on the prompt line, see prompt_sign in config.toml. LOGO_ANSI is set by
# otter-launcher.nix. Regenerate the art with (each row ends with a reset):
#   chafa --format=symbols --size=14x6 --fg-only --symbols=block+border+space --colors=full \
#     assets/nix-logo-work/nix-logo-solid-tight.png
esc=$'\e'

# Catppuccin Mocha, truecolor.
fg() { printf '%s[38;2;%sm' "$esc" "$1"; }
lavender=$(fg "180;190;254") blue=$(fg "116;199;236") peach=$(fg "250;179;135")
yellow=$(fg "249;226;175") dim=$(fg "108;112;134") off="${esc}[0m"

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

# Nerd font icons: NixOS snowflake, calendar, clock.
info=(
  "${lavender}${esc}[1m🐚 Z Shell${off}"
  "${dim}────────────────────${off}"
  "${blue}NIX  $HOSTNAME${off}"
  "${peach}  $(date '+%a %d %b')${off}"
  "${yellow}  $(date '+%H:%M') $sun${off}"
)
info[2]=${info[2]/NIX/}
for i in "${!info[@]}"; do
  printf '%s  %s\n' "${logo[i]}" "${info[i]}"
done
