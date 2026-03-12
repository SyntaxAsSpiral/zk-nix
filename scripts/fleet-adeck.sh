#!/usr/bin/env bash
# Fleet backing script: adeck
# Outputs JSON for HyprPanel custom/fleet-adeck module

LOCK="/tmp/fleet-adeck.lock"

if [[ -f "$LOCK" ]]; then
  op=$(cat "$LOCK")
  alt="building"
  state="building... ($op)"
  echo "{\"alt\": \"$alt\", \"tooltip\": \"adeck · $state\", \"text\": \"\"}"
  exit 0
fi

if ! tailscale ping -c 1 --timeout 2s adeck >/dev/null 2>&1; then
  echo "{\"alt\": \"unreachable\", \"tooltip\": \"adeck offline\", \"text\": \"\"}"
  exit 0
fi

alt="online"
gen=$(ssh -o ConnectTimeout=3 zk@adeck readlink /nix/var/nix/profiles/system 2>/dev/null | grep -o '[0-9]*$' || echo "?")

echo "{\"alt\": \"$alt\", \"tooltip\": \"adeck gen $gen · online\", \"text\": \"$gen\"}"
