# Hosts

Host files are the table of contents for each machine.

`tm20` is the Pi 3B+ print-host appliance: it does **not** import `profiles/core.nix` or Home-Manager. First boot is an sdImage (`zcli image tm20`), not a systemd-boot desktop install.

`seed` is the portable x86_64 UEFI rescue stick. It does **not** import `profiles/core.nix` or `modules/home/profiles/base.nix`: it picks only the system modules it needs, defines its own `zk` user, and gets a slim Home-Manager (nushell plus the shared CLI set). It is not a `zcli` host (no address in `zcli`'s host table), so build and install it by hand. Its `hardware-configuration.nix` is hand-written and uses filesystem labels, because the stick moves between machines.

## Promoting mutable host config

Some nxiz and zrrh app configs link into their `/etc/nixos` checkouts so GUI
changes take effect without a rebuild. Adeck's `/mnt/echo/nix-os` remains the
canonical copy. `zcli sync` sends adeck's committed and staged files to a host;
it does not bring host edits back, and it replaces edits to managed files.

For a deliberate config change on nxiz or zrrh:

1. From adeck, run `zcli sync <host> --dry`. Review every `replaced:` path and
   promote any host edit worth keeping through steps 3-5 before the real sync.
   Then preview again.
2. Run `zcli sync <host>` from adeck.
3. Make the app change on the host. In `/etc/nixos`, inspect the diff and commit
   only the selected config paths. Use `git commit --only -- <paths>` so staged
   files received from adeck are not included by accident.
4. Push the host commit to the existing `trunk` branch on GitHub. If the push is
   rejected because `trunk` advanced, reconcile the histories before retrying;
   do not force-push. Check selected files for credentials before publishing.
5. Pull the commit into adeck's canonical checkout before the next sync. Review
   that commit there, then sync hosts as needed.

Host-specific files usually avoid content conflicts, but separate commits can
still diverge in Git history. Automatic app rewrites are optional changes: review
them before committing rather than pushing every local difference. Saving these
config edits does not require a NixOS rebuild.

## Credentials and Reinstalls

The editing copy is `/mnt/echo/nix-os` on adeck; hosts build from `/etc/nixos`.
`secrets/` is ignored by Git. `zcli sync` copies it onto each target's
`/etc/nixos/secrets`; tm20 receives that copy and nothing else. Keep a separate
backup, because a Git clone cannot restore credentials. The rsync below is for
a reinstall, before `zcli` exists on the target.
Existing Git history is unchanged.

For an existing host, the order is **pull config, sync secrets, then deploy**.
The first pull that removes secrets from Git tracking can remove the old tracked
files from the checkout, so sync after pulling. No reflash is needed for tm20.

Example from adeck to nxiz (use Tailscale IPs from adeck):

```bash
rsync -a --chown=root:root --chmod=D700,F600 \
  --rsync-path='sudo -n rsync' -e 'ssh -F /dev/null' \
  /mnt/echo/nix-os/secrets/ zk@100.115.135.104:/etc/nixos/secrets/
```

Other targets: zrrh `100.77.90.79`, tm20 `100.123.184.5`.
For adeck's own build copy:

```bash
sudo rsync -a --chown=root:root --chmod=D700,F600 \
  /mnt/echo/nix-os/secrets/ /etc/nixos/secrets/
```

Do not use `--delete`: unrelated host-local files need not be removed.

| Files | Required on |
|-------|-------------|
| `wifi-password` | All hosts (seed needs nothing else, since the stick can be lost) |
| `github-token`, `github-recovery-codes` | nxiz, adeck, zrrh |
| `print-token` | tm20 |
| `hosts/<host>/ssh_host_*` | Matching host, to preserve its SSH identity |
| `nix-access-tokens.conf` | Hosts fetching private Nix inputs; tm20 provisions an empty file |

The decrypted files retain their original contents, including environment-file
syntax where applicable. `modules/secrets.nix` copies required credentials into
`/run/secrets` during activation with mode `0400`, owned by `zk`. The print token
uses group `plugdev`; other credentials use `users`. Missing or empty source
files fail that activation step before it replaces any runtime credentials.

For a fresh desktop/server install, clone the configuration into the target
root's `/etc/nixos` and copy `secrets/` there **before running `nixos-install`**.
For a target mounted at `/mnt`, that destination is `/mnt/etc/nixos/secrets`.

For a future **tm20 reinstall**, build and flash the SD image, mount its root
partition, and copy `secrets/` into that partition's `/etc/nixos/secrets` before
first boot. The image no longer embeds credentials or host keys. First-boot
activation installs its saved SSH identity and prepares Wi-Fi and print
credentials. Without that copy, Wi-Fi provisioning and the print receiver lack
their credentials. This step does not apply to the already-running tm20.

Start here when asking:

- What is enabled on this host?
- Is this behavior host-only or shared?
- Which shared modules does this machine import?

## Files

- `configuration.nix` is the system entrypoint for one host.
- `home.nix` is the Home Manager entrypoint for user-level apps and dotfiles on one host.
- `hardware-configuration.nix` is generated hardware state. Keep hardware facts there.
- Host-local assets, such as monitor XML, stay beside the host that owns them.

## What Belongs Here

Put config in `hosts/<host>/configuration.nix` when it is only true for that host:

- physical hardware details
- compositor/display choices
- host-only services
- host identity, such as `my.host = "nxiz";`
- one-off options that are clearer next to the host

Put config in `hosts/<host>/home.nix` when it is user-level and host-only:

- apps only installed on that host
- host-specific Home Manager imports
- one-off wrappers or derivations used only there

## What Belongs Elsewhere

- Shared system behavior belongs in `modules/`.
- Shared user behavior belongs in `modules/home/`.
- Package pins and overrides belong in `overlays/`. The registry, including when each hold can come off, is `overlays/README.md`.
- Host divergence inside a shared module should usually be a visible `perHost` map keyed by `config.my.host`.

The goal is not fewer lines. The goal is fast orientation: open the host file, see what the host is made of, then follow imports to the shared policy.
