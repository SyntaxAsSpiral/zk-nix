# Read one beads issue as markdown in glow. Run it from otter's bd picker.
# Usage: otter-bd-read workspace-root issue-id
export BD_JSON_ENVELOPE=1
cd "$1" || exit 1
bd show "$2" --json 2> /dev/null |
  jq -r '
    (if .data then .data else . end | if type == "array" then .[0] else . end)
    | "# \(.title)\n",
      "`\(.id)` · \(.status) · P\(.priority) · \(.issue_type) · created \(.created_at[:10])\n",
      (["description", "design", "acceptance_criteria", "notes"][] as $k
       | select(.[$k] // "" | length > 0)
       | "## \($k | gsub("_"; " ") | .[:1] | ascii_upcase)\($k | gsub("_"; " ") | .[1:])\n\n\(.[$k])\n")' |
  glow --pager -
