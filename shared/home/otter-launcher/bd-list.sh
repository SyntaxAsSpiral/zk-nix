# Live beads issues from every workspace on this host, one tab-separated row each:
# workspace root, id, status, priority, title.
export BD_JSON_ENVELOPE=1
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

n=0
while IFS= read -r root; do
  n=$((n + 1))
  (
    cd "$root" &&
      bd list --json --limit 0 --status open,in_progress,blocked,deferred 2>/dev/null |
      jq -r --arg root "$root" '.data[] | [$root, .id, .status, "P\(.priority)", .title] | @tsv'
  ) > "$tmp/$n" 2>/dev/null &
done < <(otter-fd --type d --max-depth 4 --exclude .worktrees '^\.beads$' | sed 's|/\.beads/$||')
wait

cat "$tmp"/* 2>/dev/null || true
