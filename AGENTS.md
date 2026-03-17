# AGENTS.md

Guidance for working in this repo.

## What This Is

One meshed NixOS system expressed through three hosts: **nxiz**, **adeck**, **zrrh**.

Think one tree with three trunks:
- **adeck** branches early as the **service gateway**
- **nxiz** and **zrrh** are the larger intertwined trunks for interactive work, compute, media, and heavier state

Single operator: **zk**. Repo: `/mnt/repository/nix-os`.

## Shared Substrate

All hosts share:

- one flake
- flat shared modules under `modules/`
- per-host branching via `config.my.host`
- Tailscale mesh
- Tailscale mesh + Taildrive for cross-host file access
- LM Studio on all hosts via LM Link
- shared home substrate in `modules/home/xdg.nix`
- agenix for secrets management
- nix-colors (base16 catppuccin-macchiato) via `modules/home/catppuccin.nix`

Treat host differences as divergence inside one system, not three separate systems.

## Secrets

Secrets are managed with **agenix**. Git history was wiped and reinitialized to purge plaintext secrets.

- `secrets/` contains age-encrypted keys, tokens, and Wi-Fi password
- `secrets/secrets.nix` defines age recipients
- Per-host SSH host keys live in `secrets/hosts/{hostname}/`
- `nix-access-tokens.conf` is `!include`d in `nix.extraOptions`
- agenix is wired into both NixOS and home-manager via flake modules

## Build & Deploy

`zcli` is the primary rebuild/deploy tool. It is a **mesh build/deploy wrapper**, not a general maintenance tool.

It auto-stages tracked changes:

```bash
git -C <flake> add -A
```

### Primary workflow

```bash
# Dry builds
zcli build nxiz --dry
zcli build adeck --dry
zcli build zrrh --dry
zcli build all --dry

# Build
zcli build nxiz
zcli build adeck
zcli build zrrh

# Deploy
zcli deploy nxiz
zcli deploy adeck
zcli deploy zrrh
zcli deploy all
```

### zcli behavior

- on **nxiz** and **adeck**: evaluate locally, build on **zrrh**
- on **zrrh**: build/deploy locally
- checks Tailscale reachability for remote builder/targets
- uses local flake state directly; no git remote sync assumptions

### Direct rebuild escape hatch

Use direct `nixos-rebuild` only when bypassing `zcli` is intentional.

```bash
# run on nxiz
sudo nixos-rebuild dry-build --flake /mnt/repository/nix-os#nxiz --build-host zk@zrrh
sudo nixos-rebuild switch --flake /mnt/repository/nix-os#nxiz --build-host zk@zrrh
```

Notes:
- keeps heavy compile load off nxiz
- **zrrh policy:** always build/apply zrrh locally on zrrh
- if build-host SSH fails, check `/root/.ssh/known_hosts` and remote non-login PATH for `nix` and `nix-store`

## Host Topology

| Host | Role | Desktop shell | GPU | LM Studio role | Build role |
|---|---|---|---|---|---|
| `nxiz` | primary interactive workstation trunk | Hyprland + hyprpanel | NVIDIA RTX 3070 | local GUI, embeddings, small/medium inference, mesh participant | evaluates locally, builds on `zrrh` |
| `adeck` | service gateway; always-on relay and persistent endpoint host | Niri + Waybar (minimal) | AMD Steam Deck APU (Jovian-NixOS) | stable LM Link relay endpoint and lightweight participant | evaluates locally, builds on `zrrh` |
| `zrrh` | heavy compute/media trunk | Niri + Noctalia | NVIDIA RTX 4090 | primary heavy GPU inference node | builds locally; primary mesh build host |

### Persistent endpoint strategy

Default persistent network surface: **adeck**.

Put services on adeck when they need:
- stable uptime
- stable mesh addressability
- availability while the workstation sleeps

Current adeck services:
- LM Studio / LM Link relay endpoint: `http://adeck:1234/v1`
- qBittorrent daemon + web UI (`https://adeck.tail293e98.ts.net:8080`)
- pulse-generator (daily systemd timer)
- msgvault (email/messaging archiver, home at `/mnt/vault/@raw`)
- *claw agent runtimes (nullclaw, zeroclaw, picoclaw)
- Docker

## Architecture

### Host layout

Each host has:
- `hosts/{hostname}/configuration.nix`
- `hosts/{hostname}/home.nix`
- `hosts/{hostname}/hardware-configuration.nix`

Shared behavior lives in `modules/`. Hosts cherry-pick imports. Keep layout flat.

### Per-host branching pattern

`options.my.host` is declared in `modules/system.nix`:

```nix
nxiz | adeck | zrrh
```

Common pattern:

```nix
let
  perHost = {
    nxiz = { ... };
    adeck = { ... };
    zrrh = { ... };
  };
  h = perHost.${config.my.host};
in { ... }
```

Used across system and home modules.

### Desktop shell surfaces

- **nxiz** → Hyprland + hyprpanel + swww
- **adeck** → Niri + Waybar + kaleidux
- **zrrh** → Niri + Noctalia

These are peer shell layers of the same system.

### Shared home substrate

`modules/home/xdg.nix` centralizes:
- XDG base dirs
- user dirs
- MIME defaults
- session vars
- wallpaper population into `~/Images/wallpapers`

Do not scatter this back into per-host `home.nix` without a real host-specific need.

### Visual assets

Per-host wallpaper sources:
- `assets/wallpapers/wp-nxiz`
- `assets/wallpapers/wp-adeck`
- `assets/wallpapers/wp-zrrh`

`modules/home/xdg.nix` populates `~/Images/wallpapers` from these.

Each host also declares its own `.face` in host `home.nix`. Treat `.face` as shell identity state.

## Mesh Services & Data Flows

### Inference mesh

All hosts run LM Studio. LM Link federates them.

- stable relay endpoint: `http://adeck:1234/v1`
- **zrrh**: primary heavy GPU node
- **nxiz**: workstation-side participant for GUI use, embeddings, smaller workloads
- **adeck**: always-on relay surface and lightweight participant

Per-host config:
- `modules/home/lmstudio/nxiz/`
- `modules/home/lmstudio/adeck/`
- `modules/home/lmstudio/zrrh/`

### Taildrive mesh

Defined in `modules/storage.nix`. Each host declares Taildrive shares for its local disks. Shares are registered via a systemd oneshot after tailscaled comes online.

Ownership:
- `nxiz` → `/mnt/repository`, `/mnt/archive`
- `zrrh` → `/mnt/media`, `/mnt/games`
- `adeck` → `/mnt/vault`

Cross-host access is via Taildrive WebDAV (`http://100.100.100.100:8080/{tailnet}/{host}/{share}`), browsable through Thunar bookmarks on GUI hosts. No NFS, no mount dependencies, no boot-order issues.

### Vault subvolume layout (adeck)

`/mnt/vault` is btrfs with named subvolumes:
- `@raw` — msgvault archive home (`MSGVAULT_HOME`)
- `@staging` — qBittorrent download staging

### Torrent/media ingress

`adeck` hosts qBittorrent.

Flow:
- downloads land in `/mnt/vault/@staging/`
- completed content auto-transfers via scp to `zk@zrrh:/mnt/media/Incoming/`

adeck is the ingress point; zrrh is the media landing zone.

### Data ingestion (adeck)

- **msgvault**: email/messaging archiver (DuckDB/Parquet + SQLite FTS5), home at `/mnt/vault/@raw`
- **\*claw agents**: nullclaw, zeroclaw, picoclaw — agent runtimes for data collection and processing

## Network Model

Tailscale is the primary network fabric.

`modules/networking.nix` enables:
- Tailscale SSH
- client routing via `services.tailscale.useRoutingFeatures = "client"`

VPN: **Mullvad via Tailscale addon** on adeck. This provides mesh-wide exit-node routing when needed.

## Current Realities / Open Issues

- **Performance Stack (CGN):** active on **nxiz** and **zrrh** via `modules/performance.nix`
- **zrrh 4K Wayland bug:** HDMI-to-TV 4K still fails under Wayland while working under X11/Windows
- **CPU isolation / compositor affinity:** mapped, not yet active

## Module Map

### System modules (`modules/`)

| Module | Scope |
|---|---|
| `system.nix` | core Nix settings, locale, `my.host`, auto-upgrade |
| `boot.nix` | bootloader, kernel, Plymouth, per-host boot behavior |
| `user.nix` | user `zk`, shell setup, getty autologin |
| `services.nix` | SSH, mosh, nix-ld, Bluetooth, PipeWire |
| `networking.nix` | NetworkManager, Tailscale, firewall, DNS, client routing |
| `storage.nix` | local disk mounts and Taildrive share registration |
| `packages.nix` | shared system packages |
| `overlays.nix` | package overrides and overlay glue |
| `fonts.nix` | system-wide font packages and esoteric font collection |
| `nh.nix` | GC policy and per-host flake path behavior |
| `nvidia.nix` | NVIDIA proprietary driver stack (`nxiz`, `zrrh`) |
| `steam.nix` | Steam + Gamescope + proton-ge (`nxiz`, `zrrh`) |
| `performance.nix` | CachyOS kernel, CPU governor, scheduler tuning (`nxiz`, `zrrh`) |
| `pulse-generator.nix` | adeck-only daily systemd timer |
| `qbittorrent.nix` | adeck-only torrent daemon with HTTPS UI and media handoff |
| `quickshell.nix` | Qt6/Quickshell environment for custom shell widgets |
| `openrgb/` | RGB lighting control (profiles, effects) |
| `greetd.nix` / `ly.nix` | display managers; inert unless explicitly enabled |

### Home modules (`modules/home/`)

Important anchors:

- `cli/`
  - includes `cli/zcli.nix`, the mesh build/deploy wrapper
- `lmstudio/{host}/`
  - per-host LM Studio participation
- `hyprland/` + `hyprpanel/`
  - nxiz shell stack
- `niri/` + `waybar/`
  - adeck graphical stack
- `noctalia/`
  - zrrh shell layer
- `terminal/`
  - host-sensitive terminal setup (`kitty`, `ghostty`, `alacritty`)
- `xdg.nix`
  - shared XDG dirs, MIME defaults, session vars, wallpaper population
- `nushell.nix`
  - login shell and compositor/session startup
- `catppuccin.nix`
  - nix-colors base16 palette (catppuccin-macchiato)
- `msgvault.nix`
  - email/messaging archiver (adeck-enabled)
- `kaleidux.nix`
  - dynamic wallpaper daemon (video + GLSL transitions)
- `fsel.nix`
  - TUI app launcher / dmenu / clipboard manager
- `swww.nix`
  - Wayland wallpaper daemon (nxiz)
- `thunar.nix`
  - Thunar file manager: packages, thunarrc, bookmarks, custom actions (nxiz, zrrh)
- `quickshell/`
  - custom Qt6/QML shell widgets

Other common domains:
- `editors/`
- `browser/`
- `mods/`
- `otter-launcher/`
- `spotify.nix`
- `gtk.nix`
- `icons.nix`
- `python.nix`
- `ssh.nix`

## Host Notes

### nxiz
- primary daily driver workstation
- getty autologin → nushell login flow → Hyprland on TTY1
- logging out of Hyprland drops back to nushell
- `programs.appimage.binfmt` enabled
- hyprpanel and `.face` are part of shell identity
- Wake-on-LAN enabled on wired NIC
- gnome-keyring for credential storage
- swww for wallpaper management

### adeck
- service gateway and persistent endpoint host
- Jovian-NixOS for Steam Deck hardware support
- flake path is at `/etc/nixos`
- `boot.loader.efi.canTouchEfiVariables = false`
- graphical stack is intentionally minimal (Niri + Waybar + kaleidux)
- Docker enabled
- qBittorrent runs here (staging to `@staging`, auto-scp to zrrh)
- msgvault runs here (archive at `@raw`)
- *claw agent runtimes (nullclaw, zeroclaw, picoclaw)
- brightness restore service forces 100% on boot

### zrrh
- heavy compute/media host
- always build/apply zrrh locally on zrrh
- Niri + Noctalia
- LM Studio CUDA-heavy node
- Noctalia wallpaper rotation is active
- `programs.appimage.binfmt` enabled
- Thunar + plugins for file management (nxiz, zrrh via `modules/home/thunar.nix`)
- gamemode enabled
- LACT for GPU control
- OpenRGB for lighting
- xwayland-satellite for X11 app compat

## Conventions

- **flat modules:** keep shared modules under `modules/`
- **per-host cherry-picking:** import only what a host needs
- **persistent endpoints:** default to **adeck** unless hardware says otherwise
- **build workflow:** prefer `zcli build` / `zcli deploy`
- **shared home substrate:** keep XDG/MIME/session/wallpaper logic in `modules/home/xdg.nix`
- **shell identity assets:** keep host `.face` assets in host `home.nix`
- **secrets:** managed with agenix; `secrets/` contains encrypted keys, tokens, and Wi-Fi password
- **assets:** `assets/` holds fonts, icons, GTK themes, wallpapers, and host identity imagery

## Post-Install / Bootstrap

- `tailscale up`
- Wi-Fi:
  - `nmcli device wifi connect <SSID> password $(cat /mnt/repository/nix-os/secrets/wifi-password)`
- Firefox: login, import Stylus settings from `modules/home/browser/stylus-import-frappe-sapphire.json`
- `gh auth login`
- configure mods in `modules/home/mods/mods.yml`