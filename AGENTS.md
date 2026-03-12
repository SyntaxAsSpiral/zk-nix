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
- NFS automount mesh
- LM Studio on all hosts via LM Link
- shared home substrate in `modules/home/xdg.nix`

Treat host differences as divergence inside one system, not three separate systems.

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
| `adeck` | service gateway; always-on relay and persistent endpoint host | minimal graphical session; current stopgap is Niri + Waybar | AMD Steam Deck APU | stable LM Link relay endpoint and lightweight participant | evaluates locally, builds on `zrrh` |
| `zrrh` | heavy compute/media trunk | Niri + Noctalia | NVIDIA RTX 4090 | primary heavy GPU inference node | builds locally; primary mesh build host |

### Persistent endpoint strategy

Default persistent network surface: **adeck**.

Put services on adeck when they need:
- stable uptime
- stable mesh addressability
- availability while the workstation sleeps

Current examples:
- LM Studio / LM Link relay endpoint: `http://adeck:1234/v1`
- qBittorrent daemon + web UI

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

- **nxiz** → Hyprland + hyprpanel
- **adeck** → minimal graphical session; current stopgap is Niri + Waybar
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

### NFS mesh

Defined in `modules/taildrive.nix`. Systemd automount, lazy mount-on-access, idle timeout.

Ownership:
- `nxiz` → `/mnt/repository`, `/mnt/archive`
- `zrrh` → `/mnt/media`, `/mnt/games`
- `adeck` → `/mnt/vault`

Cross-host mounts:
- `nxiz:/mnt/repository` → `adeck`, `zrrh`
- `zrrh:/mnt/media` → `nxiz`, `adeck`
- `adeck:/mnt/vault` → `nxiz`, `zrrh`

### Torrent/media ingress

`adeck` hosts qBittorrent.

Flow:
- downloads land in `/mnt/vault/torrents/`
- completed content transfers to `zk@zrrh:/mnt/media/Incoming/`

adeck is the ingress point; zrrh is the media landing zone.

## Network Model

Tailscale is the primary network fabric.

`modules/networking.nix` enables:
- Tailscale SSH
- client routing via `services.tailscale.useRoutingFeatures = "client"`

This supports exit-node/client-routing behavior, including Mullvad-backed routing where needed.

PIA-related config may still exist in-repo, but it is not current centerpiece architecture.

## Current Realities / Open Issues

- **Performance Stack (CGN):** active on **nxiz** and **zrrh** via `modules/performance.nix`
- **zrrh 4K Wayland bug:** HDMI-to-TV 4K still fails under Wayland while working under X11/Windows
- **CPU isolation / compositor affinity:** mapped, not yet active
- **adeck compositor:** current Niri setup is a stopgap; long-term goal is a minimal graphical surface

## Module Map

### System modules (`modules/`)

| Module | Scope |
|---|---|
| `system.nix` | core Nix settings, locale, `my.host`, auto-upgrade |
| `boot.nix` | bootloader, kernel, Plymouth, per-host boot behavior |
| `user.nix` | user `zk`, shell setup, getty autologin |
| `services.nix` | SSH, mosh, nix-ld, Bluetooth, PipeWire |
| `networking.nix` | NetworkManager, Tailscale, firewall, DNS, client routing |
| `taildrive.nix` | NFS mounts/exports and local filesystem topology |
| `packages.nix` | shared system packages |
| `overlays.nix` | package overrides and overlay glue |
| `nh.nix` | GC policy and per-host flake path behavior |
| `nvidia.nix` | NVIDIA proprietary driver stack (`nxiz`, `zrrh`) |
| `steam.nix` | Steam + Gamescope + proton-ge (`nxiz`, `zrrh`) |
| `pulse-generator.nix` | adeck-only daily systemd timer |
| `qbittorrent.nix` | adeck-only torrent daemon with HTTPS UI and media handoff |
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

Other common domains:
- `editors/`
- `browser/`
- `mods/`
- `otter-launcher/`
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

### adeck
- service gateway and persistent endpoint host
- flake path is NFS-backed at `/mnt/taildrive/repository/nix-os`
- `boot.loader.efi.canTouchEfiVariables = false`
- graphical stack is intentionally minimal-ish and provisional
- Docker enabled
- qBittorrent runs here
- brightness restore service forces 100% on boot

### zrrh
- heavy compute/media host
- always build/apply zrrh locally on zrrh
- Niri + Noctalia
- LM Studio CUDA-heavy node
- Noctalia wallpaper rotation is active

## Conventions

- **flat modules:** keep shared modules under `modules/`
- **per-host cherry-picking:** import only what a host needs
- **persistent endpoints:** default to **adeck** unless hardware says otherwise
- **build workflow:** prefer `zcli build` / `zcli deploy`
- **shared home substrate:** keep XDG/MIME/session/wallpaper logic in `modules/home/xdg.nix`
- **shell identity assets:** keep host `.face` assets in host `home.nix`
- **secrets:** `secrets/` contains keys, tokens, and Wi-Fi password; `nix-access-tokens.conf` is `!include`d in `nix.extraOptions`
- **assets:** `assets/` holds fonts, icons, GTK themes, wallpapers, and host identity imagery
- **reference copies:** `reference/` is archival; do not edit

## Post-Install / Bootstrap

- `tailscale up`
- Wi-Fi:
  - `nmcli device wifi connect <SSID> password $(cat /mnt/repository/nix-os/secrets/wifi-password)`
- Firefox: login, import Stylus settings from `modules/home/browser/stylus-import-frappe-sapphire.json`
- `gh auth login`
- configure mods in `modules/home/mods/mods.yml`
