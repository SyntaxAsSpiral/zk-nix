#!/usr/bin/env bash
# check-nix-updates.sh — flake input staleness for hyprpanel updates module
#
# Modes:
#   (no args)   → fast: count inputs whose locked rev != latest on branch (network)
#   -tooltip    → fast: list stale input names
#   -check      → slow: full network check, human-readable output for terminal

FLAKE="/mnt/repository/nix-os"
MODE="${1:-}"

metadata=$(nix flake metadata "$FLAKE" --json 2>/dev/null)
if [[ -z "$metadata" ]]; then
    echo "0"; exit 0
fi

get_inputs() {
    echo "$metadata" | python3 -c "
import json, sys
data = json.load(sys.stdin)
nodes = data['locks']['nodes']
root_inputs = nodes.get('root', {}).get('inputs', {})
for alias, node_key in root_inputs.items():
    if isinstance(node_key, list): continue
    node = nodes.get(node_key, {})
    locked = node.get('locked', {})
    if locked.get('type') != 'github': continue
    ref = node.get('original', {}).get('ref', 'HEAD')
    print(f\"{alias}|{locked.get('owner','')}|{locked.get('repo','')}|{ref}|{locked.get('rev','')}\")
"
}

check_stale() {
    local verbose="${1:-}"
    local stale=()

    while IFS= read -r line; do
        name=$(cut -d'|' -f1 <<< "$line")
        owner=$(cut -d'|' -f2 <<< "$line")
        repo=$(cut -d'|' -f3 <<< "$line")
        ref=$(cut -d'|' -f4 <<< "$line")
        locked_rev=$(cut -d'|' -f5 <<< "$line")
        [[ -z "$owner" || -z "$repo" ]] && continue
        ref="${ref:-HEAD}"

        latest=$(curl -sf "https://api.github.com/repos/${owner}/${repo}/commits/${ref}" \
            -H "Accept: application/vnd.github.v3+json" \
            | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['sha'])" 2>/dev/null)

        [[ -z "$latest" ]] && continue
        if [[ "$latest" != "$locked_rev" ]]; then
            if [[ -n "$verbose" ]]; then
                stale+=("$name: ${locked_rev:0:7} → ${latest:0:7}")
            else
                stale+=("$name")
            fi
        fi
    done < <(get_inputs)

    printf '%s\n' "${stale[@]}"
}

case "$MODE" in
    -check)
        echo "Checking flake inputs against upstream..."
        echo ""
        stale=$(check_stale verbose)
        if [[ -z "$stale" ]]; then
            echo "✓ All inputs up to date"
        else
            echo "Stale inputs:"
            echo "$stale"
        fi
        echo ""
        echo "--- press enter to close ---"
        read
        ;;
    -tooltip)
        stale=$(check_stale)
        if [[ -z "$stale" ]]; then
            echo "All inputs up to date"
        else
            count=$(echo "$stale" | wc -l)
            echo "$count input(s) may have updates"
            echo "$stale"
        fi
        ;;
    *)
        stale=$(check_stale)
        if [[ -z "$stale" ]]; then
            echo "0"
        else
            echo "$stale" | wc -l
        fi
        ;;
esac
