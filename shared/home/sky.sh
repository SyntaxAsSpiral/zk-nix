# sky: a small snapshot of the sky from sideriod's gnomon on adeck. Two columns of planets with
# sign, degree and a retrograde mark, the moon's phase, and the three tightest aspects.
esc=$'\e'
yellow="${esc}[33m" red="${esc}[31m" dim="${esc}[90m" off="${esc}[0m"

json=""
for url in http://127.0.0.1:8878 http://adeck:8878; do
  if json=$(curl -sf -m 2 "$url/api/chart?kind=sky"); then break; fi
done
if [ -z "$json" ]; then
  echo "sky: sideriod is unreachable (adeck:8878)" >&2
  exit 1
fi

glyphs='{"Sun":"☉","Moon":"☽","Mercury":"☿","Venus":"♀","Mars":"♂","Jupiter":"♃","Saturn":"♄","Uranus":"♅","Neptune":"♆","Pluto":"♇"}'

# Sun, mercury, mars, saturn, neptune down the left; moon, venus, jupiter, uranus, pluto down the right.
mapfile -t rows < <(jq -r --argjson g "$glyphs" '
  . as $d
  | ["Sun","Mercury","Mars","Saturn","Neptune","Moon","Venus","Jupiter","Uranus","Pluto"][] as $b
  | $d.positions[$b]
  | [$g[$b], .sign, (.sign_degree | floor), (if .retrograde then "℞" else "" end)]
  | @tsv' <<< "$json")

# The moon's phase: its elongation from the sun in eighths of a circle.
elong=$(jq -r '((.positions.Moon.longitude_deg - .positions.Sun.longitude_deg) % 360 + 360) % 360' <<< "$json")
phases=(🌑 🌒 🌓 🌔 🌕 🌖 🌗 🌘)
phase=${phases[$(awk -v e="$elong" 'BEGIN { print int(e / 45 + 0.5) % 8 }')]}

cell() {
  local g s d r
  IFS=$'\t' read -r g s d r <<< "$1"
  printf '%s%s%s %-11s%s%3s°%s %s%s%s' "$yellow" "$g" "$off" "$s" "$dim" "$d" "$off" "$red" "${r:- }" "$off"
}

for i in 0 1 2 3 4; do
  line="  $(cell "${rows[i]}")   $(cell "${rows[i + 5]}")"
  if [ "$i" -eq 0 ]; then line+=" $phase"; fi
  echo "$line"
done

# The three tightest aspects.
aspects=$(jq -r --argjson g "$glyphs" '
  {"conjunction":"☌","sextile":"⚹","square":"□","trine":"△","opposition":"☍"} as $a
  | .aspects | sort_by(.orb_deg) | .[:3][]
  | "\($g[.source])\($a[.aspect] // "·")\($g[.target]) \((.orb_deg * 10 | round) / 10)°"' <<< "$json" | paste -sd' ' | sed 's/ \([^ ]*☌\|[^ ]*⚹\|[^ ]*□\|[^ ]*△\|[^ ]*☍\)/   \1/g')
echo "  ${dim}${aspects}${off}"
