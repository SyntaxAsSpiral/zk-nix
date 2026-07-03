# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

NixOS flake for the `zk` Tailscale mesh. Three hosts share modules from `modules/` and override per-host concerns under `hosts/<host>/`. Home-Manager is wired into each `nixosConfigurations.<host>` entry in `flake.nix` rather than running standalone.

## Hosts

| Host  | Role                                 | Notable                                                       |
|-------|--------------------------------------|---------------------------------------------------------------|
| nxiz  | Primary workstation, Hyprland, NVIDIA RTX 3070 | `stateVersion = "25.11"`, uses `nix-cachyos-kernel` overlay  |
| zrrh  | Daemon Forge / central builder, Niri compositor, NVIDIA RTX 4090 | `stateVersion = "25.11"`, uses `nix-cachyos-kernel` overlay |
| adeck | Agentic server on Steam Deck hardware, Niri compositor | Jovian module, `stateVersion = "24.11"`, `canTouchEfiVariables = false` |

## Build / deploy

Primary entrypoint is `zcli` (defined in `modules/home/cli/zcli.nix`). It wraps `nixos-rebuild` with mesh-aware build/target host selection.

```bash
zcli build  <host|all> [--dry]   # eval local, build on zrrh when remote
zcli deploy <host|all> [--dry]   # build + switch; --dry = dry-activate
```

Behavior:
- `zcli` runs `git -C /mnt/repository/nix-os add -A` before every invocation so new files are included.
- Eval happens on the invoking host; build is offloaded to `zrrh` via `--build-host zk@zrrh` unless already on zrrh.
- Remote deploys add `--target-host zk@<host> --sudo`.
- Connectivity to `zrrh` (and the target, if remote) is pre-checked with `tailscale ping`.

When diagnosing a build problem, prefer `zcli build <host> --dry` over raw `nixos-rebuild` so the build host/eval host split matches production.

## Lint / format / dev shell

```bash
nix fmt                 # nixfmt on the tree
nix flake check         # runs statix + deadnix via checks.x86_64-linux
nix develop             # shell with nixd, nil, nixfmt, statix, deadnix
```

`nix flake check` fails on any statix or deadnix finding — fix the source rather than suppressing.

## Architecture

### Flake outputs (`flake.nix`)

- `nixosConfigurations.{nxiz,zrrh,adeck}` — built by a `mkHost` helper in `flake.nix` that wires up `./hosts/<host>/configuration.nix`, overlays, `agenix.nixosModules.default`, and `home-manager.nixosModules.home-manager` with `home-manager.users.zk` importing `./hosts/<host>/home.nix` plus `nix-colors` + `agenix` HM modules. Host-specific flake inputs (e.g. jovian for adeck) go in the `extraModules` list argument.
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
- `modules/home/cli/zcli.nix` — HM module that builds the `zcli` wrapper via `writeShellScriptBin`, reading the flake path from `osConfig.my.flakePath`.
- `hosts/<host>/hardware-configuration.nix` — host-specific hardware; do not share across hosts.

### Secrets

- `secrets/` contains agenix-encrypted files (`*.age`) plus raw SSH host keys and a PIA config. `secrets/secrets.nix` lists recipients.
- SSH host keys are deployed via `modules/ssh-identity.nix` (part of `profiles/core.nix`), which copies from `/etc/nixos/secrets/hosts/<host>/` to `/etc/ssh/` on activation, keyed on `config.my.host`.
- `nix.extraOptions` pulls `/etc/nixos/secrets/nix-access-tokens.conf` for private flake inputs. The file is expected to exist on every built host.

### Theming

`catppuccin-nix` is currently wired into nxiz and will be replaced with `nix-colors` + `stylix`. Do **not** add catppuccin imports to `adeck` modules — its theming is intentionally unset pending migration. `nix-colors` is already available as an input and HM module.

## Scripts

`scripts/` contains mesh utility scripts: `check-nix-updates.sh` (nixpkgs update checker), `git-review.sh` (pre-deploy diff helper), `qbt-sync-zrrh.sh` (qBittorrent sync between adeck and zrrh), `watch-pkgs.conf` (watchexec config). These are invoked directly or via host services/aliases — not through a compositor panel.

## Conventions

- `.codex/` is reserved for agent state and is not tracked as a module root.
- `docs/` is edit-on-request only (per global covenant); it does not currently exist in this repo, but do not create it without an explicit ask.
- The flake directory is used directly by `zcli`; there is no "push to remote, then build" step — local changes go live on the next `zcli deploy`. Keep that in mind when committing: an unfinished edit will be deployed if someone runs `zcli deploy` while it is staged.
