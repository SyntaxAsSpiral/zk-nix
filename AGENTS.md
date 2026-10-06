# AGENTS.md

NixOS flake for the `zk` Tailscale mesh. Shared modules live in `modules/`, per-host config in `hosts/<host>/`, and Home-Manager is wired into every host in `flake.nix` except tm20.

## Hosts

| Host  | Role | Notable |
|-------|------|---------|
| nxiz  | Primary workstation, Hyprland, RTX 3070 | CachyOS kernel |
| zrrh  | Central builder (every `zcli` build runs here), Niri, RTX 4090 | CachyOS kernel; binfmt aarch64 (deploy zrrh once) |
| adeck | Agentic server on Steam Deck hardware, Niri | Jovian kernel and module |
| tm20  | Pi 3B+ print-host appliance | aarch64, no Home-Manager, SD image |
| seed  | Portable x86_64 rescue stick | Minimal on purpose. Not a `zcli` host |

## Skills

Load before working in the area: `zcli` (build, deploy, sync, image), `nixos-fleet` (adding or changing a host, where config belongs), `nixos-secrets` (any credential). All are in `.agents/skills/`.

## Rules

- Edit the flake in `/mnt/echo/nix-os` on adeck. `zcli` publishes only committed and staged files, and Nix ignores untracked ones, so `git add` new files.
- `zcli deploy` reboots hosts unless `--switch` is given. Confirm hosts and order first.
- Extend a module's `perHost` attrset for host differences. Do not branch on `hostName`.
- `nix-cachyos-kernel` has its own nixpkgs and no `follows` line; do not add one. Record every pin or hold in `overlays/README.md`, with its removal condition, in the same change.
- seed stays minimal: no core profile, no overlays, stock kernel. Do not widen it.
- `nix flake check` runs statix and deadnix and fails on any finding. Fix the source rather than suppressing.
- `docs/` is edit-on-request only. Do not create it without an explicit ask.

Ownership rules are in `modules/README.md`, host files in `hosts/README.md`, pins in `overlays/README.md`. `scripts/zcli/` is the source for `zcli`; its ConSensus commands (`zcli assemble`, `zcli sync context`, `zcli deploy context`) run `zcli-context.sh`.
