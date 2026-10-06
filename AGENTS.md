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
zcli sync context [--dry-run] [--verbose]    # ConSensus staging deploy; no commit or push
zcli deploy context [--dry-run] [--verbose]  # same deploy, then commit and push
zcli wake                     # wake zrrh; wait until SSH and nix answer
zcli build <host>           # one host: eval and build on zrrh
zcli deploy <host> [host ...] [--switch]  # boot and queue reboots, or switch now
zcli image tm20 [--dry]     # aarch64 sdImage, built on zrrh
```

`zcli build` takes one host. `zcli deploy` takes an explicit ordered host list. First flash is `zcli image tm20`, then `zcli deploy tm20` once the Pi is on the tailnet. `zcli sync context` deploys ConSensus staging on adeck and leaves git alone. `zcli deploy context` runs that same deploy, then commits and pushes. `--dry-run` previews and does not commit. Neither context command wakes zrrh.

Behavior:
- Canonical source is adeck:`/mnt/echo/nix-os`. Build and deploy sync the committed + staged snapshot, its git history, and secrets onto zrrh:`/etc/nixos` before `nh` runs. A clean canonical checkout is clean after sync. Staged changes stay staged. Unstaged files stay local. Destination edits to snapshot files are overwritten. History is fetched from that local repo.
- If zrrh is asleep, zcli sends the LAN magic packet from adeck and waits until SSH and nix answer.
- Eval and build both happen on zrrh. Deploy follows the requested host order, moving the invoking host to the end when listed. By default it runs `nh os boot` for every host before scheduling their reboots; the invoking host gets a later reboot timer. `--switch` runs `nh os switch` in that order and schedules no reboots.
- Direct `nh os ...` on a host still uses that host's local `/etc/nixos`.
- nxiz builds and activates itself with `nh os` after `zcli sync nxiz`. `zcli deploy nxiz` is for a huge shared build, such as a full flake update that includes the CachyOS kernel and Linux: zrrh builds those paths once, then the deploy reuses them on nxiz.

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

Branch inputs that set `inputs.nixpkgs.follows` track the root nixpkgs pin. An input whose URL names a commit or a tag stays put. `nix-cachyos-kernel` is pinned to its own nixpkgs so kernel patches apply cleanly, and it has no `follows` line; do not add one. Every hold that keeps a package or input off the moving pin is listed in `overlays/README.md`. Add the row, including the condition that removes it, in the same change as the pin.

### Per-host dispatch pattern

`modules/system.nix` declares `options.my.host` as an enum of `nxiz | adeck | zrrh | tm20`, plus `options.my.flakePath` (where `nh` reads the flake on that host, normally `/etc/nixos`). `zcli` publishes from adeck:`/mnt/echo/nix-os`. Shared modules that vary per host pick from a `perHost` attrset keyed on `config.my.host`. Current `perHost` attrsets: `boot.nix`, `networking.nix`, and `storage.nix` (taildrive mounts). Other modules read `config.my.host` directly, including `secrets.nix`, `services.nix`, `ssh-identity.nix`, and `qbittorrent.nix`. When adding host-specific behavior to a shared module, extend the `perHost` attrset rather than branching on `hostName`.

Each host's `configuration.nix` sets `my.host = "<name>"` and imports profiles plus only the modules unique to it:

- `modules/profiles/core.nix` — baseline for adeck, nxiz, and zrrh (system, boot, nh, user, secrets, services, storage, packages, networking, fonts, ssh-identity). tm20 imports system, networking, ssh-identity, secrets, and nh on its own and does not import this profile.
- `modules/profiles/desktop.nix` — nxiz + zrrh only (nvidia, steam, performance, thunar, appimage); adeck deliberately does not import it
- `modules/home/profiles/base.nix` — HM baseline for adeck, nxiz, and zrrh (CLI set, nushell, xdg, nano/zed, zcli, daemon-profile). Hermes is imported from `hosts/adeck/home.nix` only.
- `modules/home/profiles/desktop.nix` — HM for nxiz and zrrh (nix-colors catppuccin-macchiato, firefox, gtk, icons, spotify, thunar, fzf-emoji). adeck does not import it.

Anything in a host's `configuration.nix`/`home.nix` beyond profile imports should be genuinely unique to that host.

### Module layout

- `modules/*.nix` — system-level modules. Current set: `boot.nix`, `fonts.nix`, `greetd.nix`, `llama-tts.nix`, `networking.nix`, `nh.nix`, `nvidia.nix`, `openrgb/`, `packages.nix`, `performance.nix`, `profiles/`, `pulse-generator.nix`, `qbittorrent.nix`, `secrets.nix`, `services.nix`, `sideriod-mcp.nix`, `ssh-identity.nix`, `steam.nix`, `storage.nix`, `system.nix`, `user.nix`. Membership in `profiles/{core,desktop}.nix` determines what is shared; greetd, openrgb, pulse-generator, qbittorrent, and sideriod-mcp are imported directly by the hosts that use them. `llama-tts.nix` is imported by adeck only.
- `modules/home/` — Home-Manager modules grouped by concern. Hosts opt in by importing from `hosts/<host>/home.nix`.
  - `cli/` — bat, btop, eza, fastfetch, fish, fun, fzf, gh, git, jolt, lazygit, yazi, zcli
  - `editors/` — nano, obsidian, zed
  - `browser/` — firefox
  - `terminal/` — alacritty, ghostty, kitty
  - `hyprland/` — nxiz-only: appearance, hypridle, hyprland, hyprpanel, keybinds, monitors, windowrules
  - `niri/` — per-host configs: `adeck.nix`, `zrrh.nix`
  - `daemonturgy/` — daemon/agent tooling: `herm/`, `hermes/`, `lmstudio/{adeck,nxiz,zrrh}/`, `mods/`, `pi/`, `stackchan/`
  - `noctalia/` — per-host: `zrrh/`
  - `otter-launcher/` — launcher configs: `zrrh/`
  - `waybar/` — `adeck.nix`
  - `profiles/` — `base.nix` (adeck, nxiz, zrrh) and `desktop.nix` (nxiz + zrrh); see Per-host dispatch pattern above
  - Top-level HM modules: `awww.nix`, `awww-cycle.nix`, `bb-server.nix`, `catppuccin.nix`, `daemon-profile.nix`, `fsel.nix`, `gtk.nix`, `icons.nix`, `msgvault.nix`, `nushell.nix`, `openrgb.nix`, `python.nix`, `spotify.nix`, `thunar.nix`, `xdg.nix`
- `modules/home/cli/zcli.nix` — HM module for the `zcli` wrapper. The scripts are `scripts/zcli-sync.sh`, `scripts/zcli-context.sh`, and `scripts/zcli-run.sh`.
- `hosts/<host>/hardware-configuration.nix` — host-specific hardware; do not share across hosts.

### Secrets

- `secrets/` is gitignored. `zcli sync` copies it to the target's `/etc/nixos/secrets`. tm20 receives that copy and nothing else. Git does not store credentials. On a first install, before `zcli` exists, copy `secrets/` to `/etc/nixos/secrets` by hand and preserve file permissions.
- Required files: all hosts need `wifi-password`; nxiz/adeck/zrrh also need `github-token` and `github-recovery-codes`; tm20 also needs `print-token`. Keep existing `hosts/<host>/` SSH identities and `nix-access-tokens.conf`.
- `modules/secrets.nix` copies host-required credentials to `/run/secrets/` during activation with mode `0400`, owned by `zk`. tm20 uses group `plugdev` for its print token; other files use `users`. After flashing tm20, copy `secrets/` to `/etc/nixos/secrets` on the mounted root partition before first boot; the SD image contains no credentials.
- SSH host keys are deployed via `modules/ssh-identity.nix` (part of `profiles/core.nix`), which copies from `/etc/nixos/secrets/hosts/<host>/` to `/etc/ssh/` on activation, keyed on `config.my.host`.
- `nix.extraOptions` pulls `/etc/nixos/secrets/nix-access-tokens.conf` for private flake inputs. The file is expected to exist on every built host.

### Theming

`modules/home/catppuccin.nix` sets the Home Manager color scheme from `nix-colors` (`catppuccin-macchiato`). nxiz and zrrh import it through the desktop home profile. adeck does not import that profile, and its theming stays unset. This flake has no `catppuccin-nix` input and no stylix module.

## Scripts

`scripts/` contains mesh utility scripts: `zcli-sync.sh`, `zcli-context.sh`, and `zcli-run.sh` (the `zcli` implementation, installed by `modules/home/cli/zcli.nix`), `check-nix-updates.sh` (nixpkgs update checker), `git-review.sh` (pre-deploy diff helper), `qbt-sync-zrrh.sh` (qBittorrent sync between adeck and zrrh), `watch-pkgs.conf` (watchexec config). These are invoked directly or via host services/aliases — not through a compositor panel.

## Conventions
- `docs/` is edit-on-request only (per global covenant); it does not currently exist in this repo, but do not create it without an explicit ask.
- `zcli` publishes the committed and staged canonical snapshot from adeck, then builds it on zrrh. An unstaged edit stays on adeck. Edit the flake in `/mnt/echo/nix-os`.
- Activate nxiz with `nh os` on nxiz. Use `zcli deploy nxiz` for a huge shared build, such as a full flake update that includes the CachyOS kernel and Linux, so zrrh builds those paths once and nxiz reuses them.
