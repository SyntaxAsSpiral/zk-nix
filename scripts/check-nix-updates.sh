#!/usr/bin/env bash
# check-nix-updates.sh — specific package staleness for hyprpanel updates module
#
# Modes:
#   (no args)   → fast: count pkgs whose local version != remote version
#   -tooltip    → fast: list stale pkg names
#   -check      → slow: full check, human-readable output for terminal

MODE="${1:-}"

# Read packages from a config file (one per line, ignoring empty and comments)
CONFIG_FILE="$(dirname "$0")/watch-pkgs.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    mapfile -t PACKAGES < <(grep -v '^[[:space:]]*$' "$CONFIG_FILE" | grep -v '^[[:space:]]*#')
else
    PACKAGES=( "lmstudio" )
fi

check_stale() {
    local verbose="${1:-}"
    local stale=()

    for pkg in "${PACKAGES[@]}"; do
        if [[ "$pkg" == "nixpkgs" || "$pkg" == "core" ]]; then
            # Special fast check for the core nixpkgs flake input
            local locked_rev
            locked_rev=$(nix flake metadata /mnt/repository/nix-os --json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
nodes = data.get('locks', {}).get('nodes', {})
root_nixpkgs = nodes.get('root', {}).get('inputs', {}).get('nixpkgs')
if root_nixpkgs and root_nixpkgs in nodes:
    print(nodes[root_nixpkgs].get('locked', {}).get('rev', ''))
            " 2>/dev/null)

            local remote_rev
            remote_rev=$(curl -sf "https://api.github.com/repos/NixOS/nixpkgs/commits/nixos-unstable" \
                -H "Accept: application/vnd.github.v3+json" \
                | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('sha', ''))" 2>/dev/null)

            if [[ -n "$locked_rev" && -n "$remote_rev" && "$locked_rev" != "$remote_rev" ]]; then
                if [[ -n "$verbose" ]]; then
                    stale+=("nixpkgs (core): ${locked_rev:0:7} → ${remote_rev:0:7}")
                else
                    stale+=("nixpkgs (core)")
                fi
            fi
            continue
        fi

        # Local version (from the locally locked nixpkgs registry)
        local_ver=$(nix eval nixpkgs#"${pkg}".version --raw 2>/dev/null)
        
        # Remote version (from the latest upstream nixos-unstable)
        remote_ver=$(nix eval github:nixos/nixpkgs/nixos-unstable#"${pkg}".version --raw 2>/dev/null)

        if [[ -n "$local_ver" && -n "$remote_ver" && "$local_ver" != "$remote_ver" ]]; then
            if [[ -n "$verbose" ]]; then
                stale+=("$pkg: $local_ver → $remote_ver")
            else
                stale+=("$pkg")
            fi
        fi
    done

    printf '%s\n' "${stale[@]}"
}

case "$MODE" in
    -check)
        echo "Checking specified packages for updates..."
        echo ""
        stale_output="$(check_stale verbose)"
        if [[ -z "$stale_output" ]]; then
            echo "✓ All watched packages are up to date"
        else
            echo "Updates available:"
            echo "$stale_output"
        fi
        echo ""
        echo "--- press enter to close ---"
        read -r
        ;;
    -tooltip)
        stale_output="$(check_stale)"
        if [[ -z "$stale_output" ]]; then
            echo "All watched packages up to date"
        else
            count=$(echo "$stale_output" | wc -l)
            echo "$count package(s) have updates"
            echo "$stale_output"
        fi
        ;;
    *)
        stale_output="$(check_stale)"
        if [[ -z "$stale_output" ]]; then
            echo "0"
        else
            echo "$stale_output" | wc -l
        fi
        ;;
esac
