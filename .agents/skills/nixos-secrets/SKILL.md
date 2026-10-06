---
name: nixos-secrets
description: >
  REQUIRED whenever a credential has to reach a host in the nix-os flake. Use when asked to
  add or rotate a secret, token, Wi-Fi password, API key or SSH host key, give a service a
  credential, restore credentials after a reinstall, flash tm20, or find out why /run/secrets
  is missing a file. Triggers: secrets, secrets/, /run/secrets, /etc/nixos/secrets, wifi-password,
  github-token, print-token, nix-access-tokens.conf, ssh_host key, EnvironmentFile,
  "missing secrets", reinstall, new host credentials.
  Deploy mechanics are in the `zcli` skill. Reinstall detail is in `hosts/README.md`.
---

# nixos-secrets

Plain files, no agenix, no sops. That is deliberate: do not suggest either. Credentials live in the gitignored `secrets/` directory on
adeck, `zcli sync` copies them to each host, and an activation script stages them into
`/run/secrets`. Git never holds a credential.

## The one rule

`/nix/store` is world-readable and everything a Nix expression reads ends up in it.
**Never put a secret value in a `.nix` file.** Read it at runtime from `/run/secrets/<name>`
(`EnvironmentFile`, a `*File` option, `networking` environment files). `modules/secrets.nix`
opens with the same warning.

## How a credential travels

```
adeck:/mnt/echo/nix-os/secrets/   (gitignored, editing copy)
  → zcli sync <host>              rsync, no --delete: host-local files survive
  → <host>:/etc/nixos/secrets/
  → activation (modules/secrets.nix, modules/ssh-identity.nix)
  → /run/secrets/<name>           0400, owner zk, group users (print-token: plugdev)
  → /etc/ssh/ssh_host_*           from secrets/hosts/<host>/, if present
```

- `zcli sync` refuses to run if the canonical checkout or the destination **tracks** anything
  under `secrets/`, or if canonical `secrets/` contains symlinks.
- `zcli deploy` syncs the snapshot to **zrrh** for the build. It does not copy secrets to the
  target. A new or changed secret needs `zcli sync <target>` before the deploy that activates it.
- Activation runs at switch or at the next boot. A missing or empty source file fails the staging
  step before any existing `/run/secrets` file is replaced.

## Which files each host needs

The source of truth is the `names` list in `modules/secrets.nix`. Read that file before trusting
this table.

| File | Hosts | Consumer |
|---|---|---|
| `wifi-password` | all | NetworkManager `nmEnvironmentFiles` in `modules/networking.nix` (nxiz, tm20, seed) |
| `github-token`, `github-recovery-codes` | nxiz, adeck, zrrh | staged only; no consumer found in this repo |
| `print-token` | tm20 | `EnvironmentFile` of `print-receiver` in `hosts/tm20/` |
| `hosts/<host>/ssh_host_{ed25519,rsa}_key[.pub]` | the matching host | `modules/ssh-identity.nix`; silently skipped when absent (seed has none) |
| `nix-access-tokens.conf` | hosts fetching private inputs | `!include` in `modules/system.nix`; tm20 gets an empty file from `hosts/tm20/` |

seed gets `wifi-password` only, because the stick can be lost or left plugged in. Do not widen that.
tm20 has a deliberate 20 s wait in this activation step. See the next section before touching it.

## tm20 boot delay

The 20 s `sleep` at the start of tm20's `mesh-secrets` activation (`modules/secrets.nix`) is crucial.
It replaces the time agenix decryption used to take in the boot cycle, and without it tm20 reset-loops.
Do not remove, shorten, or move it out of activation.

## Adding a secret

1. Create the file in `/mnt/echo/nix-os/secrets/`, mode `0600`. It is never staged or committed.
2. Add its name to `names` in `modules/secrets.nix`, under the host condition that needs it.
   Use a non-default group only when a service user needs it (as `print-token` does).
3. Consume it from `/run/secrets/<name>`, not from the source path or a Nix string.
4. `zcli sync <host>` for every host that needs it, then `zcli build <host>` to check eval,
   then activate (see `zcli`).
5. Check it arrived: `ls -l /run/secrets/` on the host.

If the file is a service environment file, the service reads `KEY=value` lines. The staged copy
keeps the original contents.

## Rotating or leaking

- Rotate by replacing the file on adeck, then `zcli sync` and activate. The service must restart
  to see a new value; activation alone does not restart it.
- A secret that was ever committed, pushed, or built into a store path is leaked. Rotate it at the
  provider. Do not offer a history rewrite as a fix.
- Check a change before committing: `git diff --cached` for tokens, and
  `grep -rnE '(password|token|secret|api_?key)[[:space:]]*=[[:space:]]*"' --include='*.nix' .`

## Reinstall and first install

The editing copy is on adeck. A git clone cannot restore credentials, so keep a separate backup
of `secrets/`. Order for an existing host: **pull config, sync secrets, then deploy**.

- **Fresh install:** clone the config into the target's root, and copy `secrets/` to
  `<root>/etc/nixos/secrets` before `nixos-install` (at `/mnt` that is `/mnt/etc/nixos/secrets`).
- **Manual copy, before `zcli` exists:** use Tailscale IPs from adeck.
  `rsync -a --chown=root:root --chmod=D700,F600 --rsync-path='sudo -n rsync' -e 'ssh -F /dev/null' /mnt/echo/nix-os/secrets/ zk@<ip>:/etc/nixos/secrets/`
  Never `--delete`.
- **tm20 reflash:** the SD image holds no credentials or host keys. Copy `secrets/` to the card's
  `/etc/nixos/secrets` before first boot (`zcli image -h` prints the commands). Not needed for the
  already-running tm20.

## Troubleshooting

| Symptom | Cause |
|---|---|
| File missing in `/run/secrets` | Not in `names` for that host, source absent or empty on the host, or the host was not synced and reactivated |
| Activation error about `/etc/nixos/secrets/<name>` | Source file missing or zero-length there. `zcli sync <host>` |
| Service starts without the new value | It was not restarted after rotation |
| Wi-Fi or print receiver dead on a fresh tm20 | Card was flashed without copying `secrets/` |
| tm20 resets about 30-60 s into boot, log just ends | The 20 s activation wait is missing or moved. See the tm20 boot delay section |
| Private flake input fails to fetch | `nix-access-tokens.conf` missing or stale on that host |
| `zcli sync` says it tracks secrets | `secrets/` got staged. `git rm -r --cached secrets` |
| Host key changed after reinstall | `secrets/hosts/<host>/` was not synced first |

## Rules

- No secret values in Nix expressions, ever.
- `secrets/` stays gitignored. Do not stage it.
- `names` in `modules/secrets.nix` decides what a host receives. Keep seed minimal.
- Sync secrets to the target before the deploy that needs them.
- Keep existing `hosts/<host>/` SSH identities and `nix-access-tokens.conf` when touching `secrets/`.
- Never remove tm20's 20 s activation wait, or move it out of activation.
