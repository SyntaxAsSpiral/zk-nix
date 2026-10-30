# Search jolt's whole energy history. Rows are days and the top processes; the preview
# shows that day's power by hour. adeck only: jolt is not installed elsewhere.
# Usage: otter-jolt            pick from the history
#        otter-jolt --preview kind key   (fzf preview; reads $OTTER_JOLT_JSON)

if [ "${1:-}" = "--preview" ]; then
  kind=$2 key=$3
  if [ "$kind" = day ]; then
    jq -r --arg d "$key" '
      def spark($max): "▁▂▃▄▅▆▇█" as $b
        | if . == null then "·" else $b[([(. / $max * 7) | floor, 7] | min):][:1] end;
      (.daily_stats[] | select(.date == $d)) as $s
      | [.samples[] | select((.timestamp | localtime | strftime("%Y-%m-%d")) == $d)] as $day
      | ($day | group_by(.timestamp | localtime | strftime("%H") | tonumber)
         | map({h: (.[0].timestamp | localtime | strftime("%H") | tonumber),
                w: (map(.power_watts) | add / length)})) as $hours
      | ($hours | map(.w) | max // 1) as $max
      | "\($d)\n",
        "energy      \($s.total_energy_wh * 10 | round / 10) Wh",
        "avg power   \($s.avg_power * 10 | round / 10) W",
        "max power   \($s.max_power * 10 | round / 10) W",
        "screen on   \($s.screen_on_hours * 10 | round / 10) h",
        (if ($day | length) > 0
         then "battery     \($day | map(.battery_percent) | min | round)% to \($day | map(.battery_percent) | max | round)%",
              "samples     \($day | length)\n",
              "power by hour, peak \($max * 10 | round / 10) W",
              "00      06      12      18    23",
              ([range(0; 24)] | map(. as $h | ($hours | map(select(.h == $h))[0].w) | spark($max)) | join(""))
         else "no samples kept for this day" end)
    ' "$OTTER_JOLT_JSON"
  else
    jq -r --arg n "$key" '
      .top_processes[] | select(.process_name == $n)
      | "\(.process_name)\n",
        "avg cpu     \(.avg_cpu * 10 | round / 10) %",
        "avg memory  \(.avg_memory_mb * 10 | round / 10) MB",
        "samples     \(.sample_count)",
        "impact      \(.total_impact | round)"
    ' "$OTTER_JOLT_JSON"
  fi
  exit 0
fi

if ! command -v jolt > /dev/null; then
  echo 'jolt is only installed on adeck'
  read -rsn1
  exit 0
fi

OTTER_JOLT_JSON=$(mktemp)
export OTTER_JOLT_JSON
trap 'rm -f "$OTTER_JOLT_JSON"' EXIT
jolt history export --period all --include-samples --output "$OTTER_JOLT_JSON" > /dev/null 2>&1

# fzf expands the single-quoted info and preview commands, not the shell
# shellcheck disable=SC2016
jq -r '
  (.daily_stats | sort_by(.date) | reverse[]
   | ["day", .date, "\(.total_energy_wh * 10 | round / 10) Wh", "avg \(.avg_power * 10 | round / 10) W",
      "max \(.max_power * 10 | round / 10) W", "screen \(.screen_on_hours * 10 | round / 10) h"]),
  (.top_processes | sort_by(-.total_impact)[]
   | ["proc", .process_name, "cpu \(.avg_cpu * 10 | round / 10) %", "mem \(.avg_memory_mb | round) MB",
      "impact \(.total_impact | round)", ""])
  | @tsv' "$OTTER_JOLT_JSON" |
  fzf --delimiter '\t' --with-nth 2.. \
    --header 'days and top processes; type a date or a process name' \
    --info-command 'printf " history ($FZF_POS/$FZF_TOTAL_COUNT)"' \
    --preview 'otter-jolt --preview {1} {2}' --preview-window 'right,55%,wrap' > /dev/null
