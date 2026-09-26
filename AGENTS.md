# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Repository purpose

NixOS flake for the `zk` Tailscale mesh. Desktop hosts share modules from `modules/` and override per-host concerns under `hosts/<host>/`. Home-Manager is wired into `nixosConfigurations.{nxiz,zrrh,adeck}` in `flake.nix` rather than running standalone. `tm20` is an aarch64 appliance and skips Home-Manager.

## Hosts

| Host  | Role                                 | Notable                                                       |
|-------|--------------------------------------|---------------------------------------------------------------|
| nxiz  | Primary workstation, Hyprland, NVIDIA RTX 3070 | `stateVersion = "25.11"`, uses `nix-cachyos-kernel` overlay  |
| zrrh  | Daemon Forge / central builder, Niri compositor, NVIDIA RTX 4090 | `stateVersion = "25.11"`, cachyos; binfmt aarch64 (you deploy zrrh once) |
| adeck | Agentic server on Steam Deck hardware, Niri compositor | Jovian module, `stateVersion = "24.11"`, `canTouchEfiVariables = false` |
| tm20  | Pi 3B+ print-host appliance (replaces quita USB cottage) | `aarch64-linux`, no HM, `sd-image-aarch64`, `stateVersion = "25.11"` |

## Build / deploy

Primary entrypoint is `zcli` (`modules/home/cli/zcli.nix`). Sync publishes adeck's canonical tree. Build, deploy, and image wake zrrh if needed and run `nh` there.

```bash
zcli sync [host|all] [--dry]  # adeck:/mnt/echo/nix-os → /etc/nixos
zcli wake                     # wake zrrh; wait until SSH and nix answer
zcli build <host>           # one host: eval and build on zrrh
zcli deploy <host>          # nh os boot, then schedule a reboot and return
zcli image tm20 [--dry]     # aarch64 sdImage, built on zrrh
```

`zcli build` and `zcli deploy` take one host. First flash is `zcli image tm20`, then `zcli deploy tm20` once the Pi is on the tailnet.

Behavior:
- Canonical source is adeck:`/mnt/echo/nix-os`. Build and deploy sync the committed + staged snapshot, its git history, and secrets onto zrrh:`/etc/nixos` before `nh` runs. A clean canonical checkout is clean after sync. Staged changes stay staged. Unstaged files stay local. Destination edits to snapshot files are overwritten. History is fetched from that local repo.
- If zrrh is asleep, zcli sends the LAN magic packet from adeck and waits until SSH and nix answer.
- Eval and build both happen on zrrh. Deploy is `nh os boot`, then a reboot scheduled on the target. The command returns once that request is accepted and prints `reboot scheduled`.
- Direct `nh os ...` on a host still uses that host's local `/etc/nixos`.

When diagnosing a build, run `zcli build <host>` so eval and build happen on zrrh the same way a deploy will.

## Lint / format / dev shell

```bash
nix fmt                 # nixfmt on the tree
nix flake check         # runs statix + deadnix via checks.x86_64-linux
nix develop             # shell with nixd, nil, nixfmt, statix, deadnix
```

`nix flake check` fails on any statix or deadnix finding — fix the source rather than suppressing.

## Architecture

### Flake outputs (`flake.nix`)

- `nixosConfigurations.{nxiz,zrrh,adeck,tm20}` — built by `mkHost` in `flake.nix`. Desktop hosts get overlays and Home-Manager (`./hosts/<host>/home.nix` plus the `nix-colors` HM module). `tm20` is `{ hostPlatform = "aarch64-linux"; homeManager = false; }`. Host-specific flake inputs (e.g. jovian for adeck) go in `extraModules`.
- `formatter.x86_64-linux = nixfmt`
- `devShells.x86_64-linux.default` — the lint/dev shell above
- `checks.x86_64-linux.{statix,deadnix}` — tree lints

Inputs follow `nixpkgs` (via `inputs.nixpkgs.follows`) except `nix-cachyos-kernel`, which is intentionally pinned to its own nixpkgs so kernel patches apply cleanly. Do not add a `follows` line to it.

### Per-host dispatch pattern

`modules/system.nix` declares `options.my.host` as an enum of `nxiz | adeck | zrrh`, plus `options.my.flakePath` (where the flake lives on that host — single source of truth consumed by `nh.nix` and `zcli`). Shared modules that vary per host pick from a `perHost` attrset keyed on `config.my.host`. Current consumers: `boot.nix`, `networking.nix`, `storage.nix` (taildrive mounts), `ssh-identity.nix`, and similar. When adding host-specific behavior to a shared module, extend the `perHost` attrset rather than branching on `hostName`.

Each host's `configuration.nix` sets `my.host = "<name>"` and imports profiles plus only the modules unique to it:

- `modules/profiles/core.nix` — baseline every host imports (system, boot, nh, user, services, storage, packages, networking, fonts, ssh-identity)
- `modules/profiles/desktop.nix` — nxiz + zrrh only (nvidia, steam, performance, thunar, appimage); adeck deliberately does not import it
- `modules/home/profiles/base.nix` — HM baseline every host imports (CLI set, nushell, xdg, nano/zed, hermes, zcli, daemon-profile, user identity)
- `modules/home/profiles/desktop.nix` — HM for GUI hosts (catppuccin, firefox, gtk, icons, spotify, thunar, fzf-emoji); no catppuccin on adeck pending stylix migration

Anything in a host's `configuration.nix`/`home.nix` beyond profile imports should be genuinely unique to that host.

### Module layout

- `modules/*.nix` — system-level modules. Current set: `boot.nix`, `fonts.nix`, `greetd.nix`, `ly.nix`, `networking.nix`, `nh.nix`, `nvidia.nix`, `openrgb/`, `packages.nix`, `performance.nix`, `profiles/`, `pulse-generator.nix`, `qbittorrent.nix`, `services.nix`, `ssh-identity.nix`, `steam.nix`, `storage.nix`, `system.nix`, `user.nix`. Membership in `profiles/{core,desktop}.nix` determines what is shared; greetd/ly/openrgb/pulse-generator/qbittorrent/sideriod-mcp are imported directly by the hosts that use them.
- `modules/home/` — Home-Manager modules grouped by concern. Hosts opt in by importing from `hosts/<host>/home.nix`.
  - `cli/` — bat, btop, eza, fastfetch, fish, fun, fzf, gh, git, jolt, lazygit, yazi, zcli
  - `editors/` — nano, obsidian, zed
  - `browser/` — firefox
  - `terminal/` — alacritty, ghostty, kitty
  - `hyprland/` — nxiz-only: appearance, hypridle, hyprland, keybinds, monitors, waybar integration, windowrules
  - `niri/` — per-host configs: `adeck.nix`, `zrrh.nix`
  - `daemonturgy/` — daemon/agent tooling: `hermes/`, `lmstudio/{adeck,nxiz,zrrh}/`, `mods/`
  - `noctalia/` — per-host: `zrrh/`
  - `otter-launcher/` — launcher configs: `zrrh/`
  - `waybar/` — `adeck.nix`
  - `profiles/` — `base.nix` (all hosts) and `desktop.nix` (nxiz + zrrh); see Per-host dispatch pattern above
  - Top-level HM modules: `awww.nix`, `catppuccin.nix`, `daemon-profile.nix`, `fsel.nix`, `gtk.nix`, `icons.nix`, `kaleidux.nix`, `msgvault.nix`, `nushell.nix`, `openrgb.nix`, `python.nix`, `spotify.nix`, `thunar.nix`, `xdg.nix`
- `modules/home/cli/zcli.nix` — HM module for the `zcli` wrapper. Sync is `zcli-sync.sh`. Wake, build, deploy, and image are `zcli-run.sh`.
- `hosts/<host>/hardware-configuration.nix` — host-specific hardware; do not share across hosts.

### Secrets

- `secrets/` is ignored and synced manually over SSH with rsync. Git does not provision credentials. Copy it to `/etc/nixos/secrets` before installation or activation; preserve file permissions.
- Required files: all hosts need `wifi-password`; nxiz/adeck/zrrh also need `github-token` and `github-recovery-codes`; tm20 also needs `print-token`. Keep existing `hosts/<host>/` SSH identities and `nix-access-tokens.conf`.
- `modules/secrets.nix` copies host-required credentials to `/run/secrets/` during activation with mode `0400`, owned by `zk`. tm20 uses group `plugdev` for its print token; other files use `users`. After flashing tm20, copy `secrets/` to `/etc/nixos/secrets` on the mounted root partition before first boot; the SD image contains no credentials.
- SSH host keys are deployed via `modules/ssh-identity.nix` (part of `profiles/core.nix`), which copies from `/etc/nixos/secrets/hosts/<host>/` to `/etc/ssh/` on activation, keyed on `config.my.host`.
- `nix.extraOptions` pulls `/etc/nixos/secrets/nix-access-tokens.conf` for private flake inputs. The file is expected to exist on every built host.

### Theming

`catppuccin-nix` is currently wired into nxiz and will be replaced with `nix-colors` + `stylix`. Do **not** add catppuccin imports to `adeck` modules — its theming is intentionally unset pending migration. `nix-colors` is already available as an input and HM module.

## Scripts

`scripts/` contains mesh utility scripts: `check-nix-updates.sh` (nixpkgs update checker), `git-review.sh` (pre-deploy diff helper), `qbt-sync-zrrh.sh` (qBittorrent sync between adeck and zrrh), `watch-pkgs.conf` (watchexec config). These are invoked directly or via host services/aliases — not through a compositor panel.

## Conventions
- `docs/` is edit-on-request only (per global covenant); it does not currently exist in this repo, but do not create it without an explicit ask.
- `zcli` publishes the staged canonical snapshot from adeck, then builds it on zrrh. An unfinished edit is included once it is staged.
