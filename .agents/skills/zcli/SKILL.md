---
name: zcli
description: >
  REQUIRED before running or explaining `zcli` in the nix-os flake: sync, build,
  deploy, image, wake. Use when asked to build or deploy a host, publish the flake
  to /etc/nixos, wake zrrh, flash tm20, or when a change "didn't deploy".
  Triggers: zcli, zcli sync, zcli build, zcli deploy, zcli image, zcli wake, nh os,
  /etc/nixos out of date, unstaged, zrrh asleep, reboot scheduled.
  ConSensus commands (`zcli assemble`, `zcli sync context`) are not covered here.
---

# zcli

The canonical flake is `adeck:/mnt/echo/nix-os`. zcli publishes a snapshot of it to
`/etc/nixos` on the target, and every eval and build runs on **zrrh** through `nh`.
Source: `scripts/zcli/zcli-sync.sh` and `scripts/zcli/zcli-run.sh`, wired up by
`modules/home/cli/zcli.nix`. Valid hosts: `nxiz zrrh adeck tm20`. `seed` is not a zcli host.

## Read this first: what gets published

The snapshot is **adeck's git index**, not its working tree, plus local git history.

- Committed and staged files are published. **Unstaged edits and untracked files are not.**
  A new `.nix` file that was never `git add`ed does not exist for Nix or for zcli.
  Stage first. This is the usual reason a change "did nothing".
- A clean canonical checkout is clean after sync. Staged-but-uncommitted changes are published
  and stay staged on the destination.
- Edits made directly in a destination's `/etc/nixos` to snapshot files are overwritten.
  Untracked files that are not in the snapshot stay.
- `secrets/` is gitignored and rsynced separately. It is never deleted from the destination,
  so host-local credentials survive. tm20 receives secrets only.
- Edit in `/mnt/echo/nix-os` on adeck. Run from another host and zcli forwards to adeck over SSH.

## Which command

| Goal | Command |
|---|---|
| Publish to a host without building | `zcli sync [host\|all] [--dry]` |
| Check that a host evals and builds, no activation | `zcli build <host>` |
| Apply on one or more hosts | `zcli deploy <host> [host ...] [--switch]` |
| Make the tm20 SD card | `zcli image tm20 [--dry]` |
| Wake zrrh and wait for nix | `zcli wake` |

`sync` with no host means the invoking host; `all` means the four zcli hosts. `--dry` previews.
A flag a command does not take is an error (`--dry` is for `sync` and `image`, `--switch` for `deploy`).

## Behavior

- **build, deploy, image** wake zrrh first (WoL packet from adeck, up to 180 s for SSH and nix),
  sync the snapshot to zrrh, then hold a sleep lock there (`zcli-awake.service`) so idle suspend
  cannot interrupt the job. The lock is released on exit.
- **build** takes exactly one host and stops after `nh os build -H <host>` on zrrh. Use it to
  diagnose: it evals and builds the same way deploy will.
- **deploy** takes an explicit list of distinct hosts (`all` is rejected). It probes SSH to each
  remote host first, then follows your order with the invoking host moved last.
  - Default: `nh os boot` for every host, then schedules a reboot on each
    (2 s for one host; with several, 5 s each and 20 s for the invoking host).
  - `--switch`: `nh os switch` in order, no reboots.
  - Each built system is pinned on zrrh as a gcroot `zcli-<host>`.
- **nxiz** normally builds and activates itself with `nh os` after `zcli sync nxiz`.
  Use `zcli deploy nxiz` for a huge shared build (full flake update with the CachyOS kernel),
  so zrrh builds those paths once and nxiz reuses them.
- Direct `nh os ...` on a host uses that host's own `/etc/nixos`, not the canonical tree.

## tm20 first flash

`zcli build tm20` does not make an image. Use `zcli image tm20`.

1. `zcli image tm20` builds on zrrh and links the `.img` at `/mnt/echo/nix-os/result-sd-tm20`.
2. Flash the whole disk with `dd` (`lsblk` first; `of=` is the disk, not a partition).
3. Before first boot, mount the card's ext4 partition and rsync `secrets/` to
   `<mount>/etc/nixos/secrets/`. The image contains no credentials.
4. Once the Pi is on the tailnet, `zcli deploy tm20`.

`zcli image -h` prints the exact `lsblk`, `dd`, and mount commands.

## Adding a host to zcli

The host tables are hard-coded in the scripts. A host missing from them is rejected, and
`zcli sync` also fails when run on a host that is not in `zcli-sync.sh`'s table.

- `scripts/zcli/zcli-sync.sh`: the `address` case (Tailscale IP) and the `all)` expansion.
- `scripts/zcli/zcli-run.sh`: the `address` and `valid_host` cases, and the "valid:" error text.
- Help text in both files, and `scripts/zcli/test_zcli_sync.py` if it asserts the host list.
- The host must import `modules/home/cli/zcli.nix` (via `profiles/base.nix`, or directly as seed does).
- Flake hosts must have `/etc/nixos` as a git checkout. Appliances like tm20 get secrets only.
- Then update this skill's host list.

See `nixos-fleet` for the flake-side steps of adding a host.

## Troubleshooting

| Symptom | Cause |
|---|---|
| Change had no effect | File unstaged or untracked on adeck. `git add` it, rerun |
| `another sync/build/deploy is using /etc/nixos` | Lock held by a running zcli on that host |
| `interrupted sync: retry its original snapshot first` | Earlier sync died mid-way. Rerun it with the same snapshot (don't change the index first) |
| `zrrh did not become ready within 180s` | WoL did not land. Check zrrh power and LAN, then `zcli wake` |
| `zrrh SSH failed` | Host key or permission problem, printed above the error |
| `zrrh refused the sleep lock` | zrrh's passwordless `sudo -n systemd-run` is not working |
| `<host>: ...` before a deploy starts | SSH preflight to that host failed. Nothing was built |
| `canonical checkout tracks secrets` / `destination tracks secrets` | `secrets/` got committed. Untrack it |
| Mesh names do not resolve | Expected on adeck (Mullvad). zcli dials Tailscale IPs itself |

## Rules

- **Stage before you run.** Unstaged is invisible to zcli.
- **Diagnose with `zcli build <host>`**, not a local `nix build`, so eval and build match deploy.
- **Never hand-edit `/etc/nixos`** on a host expecting it to stick. The next sync overwrites it.
- **`zcli deploy` without `--switch` reboots machines, including adeck if it is listed.**
  Confirm hosts and order with the user before running it. Prefer `--dry`/`build` first.
- Do not run `zcli image` without `--dry` unless asked. It is a long build.
