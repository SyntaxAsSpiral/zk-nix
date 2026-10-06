---
name: nixos-fleet
description: >
  REQUIRED when changing how the nix-os flake is organized across hosts. Use when asked to add or
  change a host, share a module between hosts, stop a change landing on the wrong machine, work
  out which modules a host imports, add a perHost entry, or decide whether config belongs in
  modules/, modules/home/, hosts/<host>/ or overlays/. Triggers: mkHost, my.host, perHost,
  profiles/core.nix, profiles/desktop.nix, hosts/<host>, nxiz, zrrh, adeck, tm20, seed, "new host",
  "only on one host". Deploy mechanics are in `zcli`. Credentials are in `nixos-secrets`.
---

# nixos-fleet

One flake, five hosts. Shared policy lives in `modules/`, host-only facts in `hosts/<host>/`,
and shared modules vary per host through a `perHost` table keyed on `config.my.host`.
Ownership rules are in `modules/README.md`. Host-file conventions are in `hosts/README.md`.
Pins and holds are in `overlays/README.md`. Read those before restructuring.

## Shape

`flake.nix` builds every host with `mkHost "<name>" { extraModules, hostPlatform, homeManager }`:

- hostPlatform and the overlay list `meshOverlays.hosts.<name>` (from `overlays/default.nix`)
- `hosts/<name>/configuration.nix`
- unless `homeManager = false`: Home-Manager as a NixOS module, user `zk`, importing
  `nix-colors` and `hosts/<name>/home.nix`. A rebuild applies system and home together.
- `extraModules` for host-only flake inputs (adeck passes `jovian`).

Each `configuration.nix` sets `my.host = "<name>"` and imports profiles plus only what is unique.

| Host | System imports | Home-Manager |
|---|---|---|
| nxiz | `profiles/core` + `profiles/desktop`, `greetd` | `profiles/base` + `profiles/desktop` |
| zrrh | `profiles/core` + `profiles/desktop` | `profiles/base` + `profiles/desktop` |
| adeck | `profiles/core` (no desktop), `jovian` via `extraModules` | `profiles/base` (no desktop) |
| tm20 | `system`, `networking`, `ssh-identity`, `secrets`, `nh` itself. aarch64, no core profile | none |
| seed | `system`, `boot`, `nh`, `secrets`, `networking`, `ssh-identity` itself. No core profile, empty overlays | nushell + shared CLI imported directly |

seed skips the core set because fonts, Playwright, PipeWire and Mesa bloat the stick; it defines its
own `zk` user. Anything in a host file beyond profile imports should be unique to that host.

## perHost: where host differences go

A shared module that varies per host holds a `perHost` attrset and indexes it with
`perHost.${config.my.host}` (Home-Manager: `osConfig.my.host`). **A host missing from that table
is an eval error.** Find the tables with `grep -rn 'perHost' modules`.

- Add host behavior by **extending the table**, not by branching on `hostName`.
- Some modules read `my.host` directly (`secrets.nix`, `ssh-identity.nix`, `services.nix`,
  `qbittorrent.nix`, `terminal/alacritty.nix`, the kernel choice in `boot.nix`). Use that for a
  one-off switch, and `perHost` when several values differ.
- A table only matters to hosts that import its module. tm20 and seed skip `storage.nix` and the
  home profiles, so they need no entry there.

## Where does it go

| Situation | Put it in |
|---|---|
| True for one host only | `hosts/<host>/configuration.nix` (system) or `home.nix` (user) |
| Two or more hosts | shared module in `modules/` or `modules/home/` with a `perHost` entry |
| Package version, pin, or patch | `overlays/`, with a row in `overlays/README.md` and its removal condition |
| Hardware facts | `hosts/<host>/hardware-configuration.nix`. Never share it |
| User app or dotfile | `modules/home/`, imported from `hosts/<host>/home.nix` |

Input holds: branch inputs with `inputs.nixpkgs.follows` track the root pin. An input whose URL names
a commit or tag stays put. `nix-cachyos-kernel` has its own nixpkgs and **no `follows` line**. Do not add one.

## Adding a host

1. `hosts/<name>/configuration.nix` (sets `my.host`, imports, `stateVersion`), `hardware-configuration.nix`,
   and `home.nix` (skip for an appliance with `homeManager = false`).
2. `modules/system.nix`: add the name to the `my.host` enum **and** to the `my.flakePath` map.
3. `overlays/default.nix`: add `hosts.<name>` (`[ ]` is fine). `mkHost` indexes it.
4. `flake.nix`: add `<name> = mkHost "<name>" { ... };`.
5. `perHost` entries in every shared module the host imports (core profile: `boot`, `networking`,
   `storage`; home profiles: `nushell`, `thunar`, `xdg`, which also keys wallpapers by host).
6. `modules/secrets.nix`: the default branch hands out `github-token` and `github-recovery-codes`.
   Check it is what the host should get. Put its SSH keys in `secrets/hosts/<name>/`.
   See `nixos-secrets`.
7. zcli: see the "Adding a host to zcli" section of the `zcli` skill.
8. Update the Hosts table in `AGENTS.md` and `hosts/README.md`.
9. `git add` the new files, then `zcli build <name>`. `nix flake check` runs statix and deadnix only;
   it does not evaluate hosts.

## Troubleshooting

| Symptom | Cause |
|---|---|
| `attribute '<host>' missing` from a `perHost` or `wpSource` lookup | The host has no entry in that module's table |
| `value "<host>" is not ... enum` | The name is not in `my.host` in `modules/system.nix` |
| `attribute '<host>' missing` in `overlays/default.nix` | Add `hosts.<name>` |
| New file has no effect, or `path ... does not exist` | Untracked. `git add` it |
| A change reached the wrong host | It went into a shared module without a `perHost` split, or a profile |
| Home-Manager change does nothing on seed or tm20 | seed imports its own list in `hosts/seed/home.nix`; tm20 has no Home-Manager |

## Rules

- Extend `perHost`. Do not branch on `hostName`.
- Don't put host-only config in a shared module or shared config in a host file.
- Don't share `hardware-configuration.nix`.
- Don't add `follows` to `nix-cachyos-kernel`. Record every pin in `overlays/README.md` in the same change.
- Don't widen seed. It stays minimal on purpose.
- Fix statix and deadnix findings in the source rather than suppressing them.
