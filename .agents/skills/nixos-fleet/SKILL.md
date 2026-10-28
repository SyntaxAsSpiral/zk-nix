---
name: nixos-fleet
description: >
  Use when organizing the nix-os flake across hosts: add or change a host, share a module,
  keep a change off the wrong machine, see what a host imports, add a perHost entry, or
  choose shared/system/, shared/home/, hosts/<host>/, hosts/<host>/desk-env/, or overlays/.
  Triggers: mkHost, my.host, perHost, nxiz, zrrh, adeck, tm20, seed.
  Deploy is zcli. Credentials are nixos-secrets.
---

# nixos-fleet

One flake, five hosts. Shared leaf modules live in `shared/`. Each host file is that
machine's profile. Host-only Home Manager modules live in `hosts/<host>/desk-env/`.
Shared modules vary per host through a `perHost` table keyed on `config.my.host`.
Ownership rules are in `shared/README.md`. Host-file conventions are in `hosts/README.md`.
Pins and holds are in `overlays/README.md`. Read those before restructuring.

## Shape

`flake.nix` builds every host with `mkHost "<name>" { extraModules, hostPlatform }`:

- hostPlatform and the overlay list `meshOverlays.hosts.<name>` (from `overlays/default.nix`)
- `hosts/<name>/configuration.nix`
- Home-Manager as a NixOS module, user `zk`, importing
  `hosts/<name>/home.nix`. A rebuild applies system and home together.
- `extraModules` for host-only flake inputs (adeck passes `jovian`).

Each `configuration.nix` and `home.nix` is the profile: it lists the shared modules that
machine imports. There is one shared base, `shared/system/core.nix`: every host imports it for
`system`, `nh`, `secrets`, `networking`, `ssh-identity`, `shell`, the `zk` user, passwordless sudo,
openssh, tty1 autologin, and the SSH-to-nushell handoff. There are no other shared profiles.

| Host | System | Home-Manager |
|---|---|---|
| nxiz | shared nixos leaves, including nvidia, steam, performance; `./greetd.nix` | shared home leaves, including firefox and gtk; `./desk-env/` |
| zrrh | same workstation leaves; `./openrgb` and pia | shared home leaves; `./desk-env/` |
| adeck | shared nixos leaves, no nvidia or steam; llama-tts, pulse, qbittorrent. `jovian` via `extraModules` | shared home leaves; firefox package in `home.nix`, no gtk module; `./desk-env/` |
| tm20 | `core`, `./print-receiver.nix`. aarch64 | nushell, named in `home.nix` |
| seed | `core`, `boot`. Empty overlays. Console only | nushell, fastfetch, gh, and zcli, named in `home.nix` |

seed is `core` plus the stick, and a new host starts from it. It skips `packages.nix` and the NVIDIA/Steam modules. That set blew the stick out to 8.5 GiB.
Seed is console only, with no display server. It defines its own `zk` user in the host file.

## perHost: where host differences go

A shared module that varies per host holds a `perHost` attrset and indexes it with
`perHost.${config.my.host}` (Home-Manager: `osConfig.my.host`). **A host missing from that table
is an eval error.** Find the tables with `grep -rn 'perHost' shared hosts`.

- Add host behavior by **extending the table**, not by branching on `hostName`.
- Some modules read `my.host` directly (`secrets.nix`, `ssh-identity.nix`, `services.nix`,
  `hosts/adeck/qbittorrent.nix`, `hosts/adeck/desk-env/alacritty.nix`, the kernel choice in `boot.nix`). Use that for a
  one-off switch, and `perHost` when several values differ.
- A table only matters to hosts that import its module. tm20 and seed skip `storage.nix` and
  most of `shared/home/`, so they need no entry there.

## Where does it go

| Situation | Put it in |
|---|---|
| True for one host only | `hosts/<host>/` for NixOS, `hosts/<host>/desk-env/` for Home Manager |
| Two or more hosts | `shared/system/` or `shared/home/`, with a `perHost` entry when the values differ |
| Package version, pin, or patch | `overlays/`, with a row in `overlays/README.md` and its removal condition |
| Hardware facts | `hosts/<host>/hardware-configuration.nix`. Never share it |
| User app or dotfile | `shared/home/` when two hosts use it, otherwise `desk-env/`. The host `home.nix` imports it |

Input holds: branch inputs with `inputs.nixpkgs.follows` track the root pin. An input whose URL names
a commit or tag stays put. `nix-cachyos-kernel` has its own nixpkgs and **no `follows` line**. Do not add one.

## Adding a host

1. `hosts/<name>/configuration.nix` (sets `my.host`, imports, `stateVersion`), `hardware-configuration.nix`,
   and `home.nix`.
2. `shared/system/system.nix`: add the name to the `my.host` enum **and** to the `my.flakePath` map.
3. `overlays/default.nix`: add `hosts.<name>` (`[ ]` is fine). `mkHost` indexes it.
4. `flake.nix`: add `<name> = mkHost "<name>" { ... };`.
5. `perHost` entries in every shared module the host imports (`boot`, `networking`,
   `storage` when imported; `nushell`, `thunar`, `xdg` when imported. `xdg` keys wallpapers by host).
6. `shared/system/secrets.nix`: the default branch hands out `github-token`, `github-recovery-codes`, and `pi-openrouter-api-key`.
   adeck also gets `festin-openrouter-api-key`. Check that list is what the host should get. Put its SSH keys in `secrets/hosts/<name>/`.
   See `nixos-secrets`.
7. zcli: see the "Adding a host to zcli" section of the `zcli` skill.
8. Update the Hosts table in `AGENTS.md` and `hosts/README.md`.
9. `git add` the new files, then `zcli build <name>`. `nix flake check` runs statix and deadnix only;
   it does not evaluate hosts.

## Troubleshooting

| Symptom | Cause |
|---|---|
| `attribute '<host>' missing` from a `perHost` or `wpSource` lookup | The host has no entry in that module's table |
| `value "<host>" is not ... enum` | The name is not in `my.host` in `shared/system/system.nix` |
| `attribute '<host>' missing` in `overlays/default.nix` | Add `hosts.<name>` |
| New file has no effect, or `path ... does not exist` | Untracked. `git add` it |
| A change reached the wrong host | It went into a shared module without a `perHost` split |
| Home-Manager change does nothing on seed or tm20 | seed and tm20 import their own lists in `hosts/<host>/home.nix` |

## Rules

- Extend `perHost`. Do not branch on `hostName`.
- Don't put host-only config in a shared module or shared config in a host file.
- Don't share `hardware-configuration.nix`.
- Don't add `follows` to `nix-cachyos-kernel`. Record every pin in `overlays/README.md` in the same change.
- Don't give seed `packages.nix`, the NVIDIA or Steam modules, overlays, or a non-stock kernel.
- Fix statix and deadnix findings in the source rather than suppressing them.
