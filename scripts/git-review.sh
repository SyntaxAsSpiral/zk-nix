#!/usr/bin/env bash
# Git review module for hyprpanel
# Scans repos in /mnt/repository for uncommitted changes

SCAN_DIRS=(
  "/mnt/repository/autopoesis"
  "/mnt/repository/collectivist"
  "/mnt/repository/consensus"
  "/mnt/repository/context-vault"
  "/mnt/repository/daemonturgy/claurst"
  "/mnt/repository/daemonturgy/excalibur"
  "/mnt/repository/daemonturgy/mempalace"
  "/mnt/repository/daemonturgy/mesh-inference"
  "/mnt/repository/daemonturgy/pi"
  "/mnt/repository/forensic-files"
  "/mnt/repository/kludge-chan"
  "/mnt/repository/lexemancy-site"
  "/mnt/repository/lɛxigȫn"
  "/etc/nixos"
  "/mnt/repository/obsidian-workshop"
  "/mnt/repository/obsidian-workshop/apply-opencode"
  "/mnt/repository/obsidian-workshop/obsidian-lmstudio-connect"
  "/mnt/repository/obsidian-workshop/obsidian-sample-plugin"
  "/mnt/repository/semantic-json"
  "/mnt/repository/sideriod"
  "/mnt/repository/svadharma"
)

dirty=0
dirty_repos=""

for dir in "${SCAN_DIRS[@]}"; do
  [ -d "$dir/.git" ] || continue
  status=$(git -C "$dir" status --porcelain 2>/dev/null)
  if [ -n "$status" ]; then
    dirty=$((dirty + 1))
    name=$(basename "$dir")
    count=$(echo "$status" | wc -l)
    dirty_repos="${dirty_repos}${name}: ${count} changes\n"
  fi
done

total=${#SCAN_DIRS[@]}

if [ "$dirty" -eq 0 ]; then
  pct=100
  alt="clean"
  tip="All repos clean"
else
  pct=$((100 - (dirty * 100 / total)))
  [ "$pct" -lt 0 ] && pct=0
  alt="dirty"
  tip="${dirty_repos}${dirty}/${total} repos dirty"
fi

# Strip trailing newline from tooltip
tip=$(echo -e "$tip" | tr '\n' ' ' | sed 's/ $//')

echo "{\"percentage\": ${pct}, \"alt\": \"${alt}\", \"tooltip\": \"${tip}\", \"dirty\": ${dirty}}"
