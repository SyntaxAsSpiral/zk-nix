#!/usr/bin/env bash
# Fleet backing script: nxiz
# Outputs JSON for HyprPanel custom/fleet-nxiz module

LOCK="/tmp/fleet-nxiz.lock"

if [[ -f "$LOCK" ]]; then
  op=$(cat "$LOCK")
  alt="building"
  state="building... ($op)"
else
  alt="idle"
  state="idle"
fi

gen=$(readlink /nix/var/nix/profiles/system | grep -o '[0-9]*$' || echo "?")

echo "{\"alt\": \"$alt\", \"tooltip\": \"nxiz gen $gen · $state\", \"text\": \"$gen\"}"
