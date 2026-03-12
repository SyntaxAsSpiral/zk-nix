#!/usr/bin/env bash
# install-zrrh.sh — post-partition NixOS installer for zrrh
#
# Prerequisites:
#   1. Boot the NixOS minimal installer USB
#   2. Partition and format disks yourself
#   3. Mount root at /mnt, boot at /mnt/boot (and any subvols)
#   4. The flake repo is already on the mounted filesystem
#
# Usage:
#   bash install-zrrh.sh /mnt/path/to/nix-os
#
# What it does:
#   - Validates mounts
#   - Generates hardware-configuration.nix from live hardware
#   - Drops it into hosts/zrrh/ in the repo
#   - Runs nixos-install --flake .#zrrh

set -euo pipefail

RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[0;33m'
RST='\033[0m'

die()  { echo -e "${RED}✗ $*${RST}" >&2; exit 1; }
info() { echo -e "${GRN}▸ $*${RST}"; }
warn() { echo -e "${YLW}▸ $*${RST}"; }

# --- Args ---
FLAKE_DIR="${1:-}"
[[ -z "$FLAKE_DIR" ]] && die "Usage: bash install-zrrh.sh /mnt/path/to/nix-os"
[[ -d "$FLAKE_DIR" ]] || die "Flake directory not found: $FLAKE_DIR"
[[ -f "$FLAKE_DIR/flake.nix" ]] || die "No flake.nix in $FLAKE_DIR — wrong path?"

HWCONFIG_DEST="$FLAKE_DIR/hosts/zrrh/hardware-configuration.nix"
[[ -d "$FLAKE_DIR/hosts/zrrh" ]] || die "hosts/zrrh/ not found in flake — repo incomplete?"

# --- Validate mounts ---
info "Checking mounts..."
mountpoint -q /mnt || die "/mnt is not a mountpoint. Mount your root filesystem first."
mountpoint -q /mnt/boot || die "/mnt/boot is not a mountpoint. Mount your EFI partition first."
info "/mnt and /mnt/boot are mounted."

# Show what we're working with
echo ""
warn "Current mounts under /mnt:"
findmnt --target /mnt --real -o TARGET,SOURCE,FSTYPE,OPTIONS --noheadings -R
echo ""

# --- Generate hardware-configuration.nix ---
info "Generating hardware-configuration.nix..."
nixos-generate-config --root /mnt --show-hardware-config > "$HWCONFIG_DEST"
info "Written to $HWCONFIG_DEST"

echo ""
warn "Generated hardware-configuration.nix:"
echo "─────────────────────────────────────"
cat "$HWCONFIG_DEST"
echo "─────────────────────────────────────"
echo ""

# --- Confirm ---
read -rp "$(echo -e "${YLW}▸ Ready to nixos-install --flake ${FLAKE_DIR}#zrrh. Proceed? [y/N] ${RST}")" confirm
[[ "$confirm" =~ ^[Yy]$ ]] || die "Aborted."

# --- Install ---
info "Running nixos-install..."
nixos-install --flake "$FLAKE_DIR#zrrh" --no-root-passwd

echo ""
info "Done. Reboot, pull the USB, and zrrh is alive."
info "Post-boot: tailscale up, then zcli rebuild to confirm."
