# Hosts

Host files are the table of contents for each machine.

`tm20` is the Pi 3B+ print-host appliance: its `configuration.nix` names a short list of shared system modules, and its `home.nix` carries the shell only. First boot is an sdImage (`zcli image tm20`), not a systemd-boot desktop install.

`seed` is the portable x86_64 UEFI stick. It is the core: the base a new host is copied from, then extended, and also the rescue stick. Its `configuration.nix` and `home.nix` name the shared modules it wants and skip the rest (no `packages.nix`, no NVIDIA, no Zed). It is console only: no display server, and autologin is the tty getty. It is a `zcli` host (`zcli deploy seed`), but it is left out of `zcli sync all`, since the stick is often offline. A booted seed has `zcli`, so it can deploy itself from zrrh. Its `hardware-configuration.nix` is hand-written and uses filesystem labels, because the stick moves between machines.

## Host-local app config

nxiz and zrrh GUI configs used to be symlinks into `/etc/nixos`. `zcli sync` is
one-way from adeck, so a GUI write through that link was replaced on the next
sync. The first switch after this change copies each of those links out to a
real file, and later switches leave the file alone:

- nxiz: HyprPanel, LM Studio settings, presets, and http server config
- zrrh: Noctalia, OpenRGB, LM Studio settings, presets, and http server config

The copies in this repo are the snapshot that copy uses. After the switch they
are not the live files. `noctalia/*.json` and `hyprpanel/*` are kept as backups,
unwired. mods is declared on every host by `shared/system/shell.nix`. Niri is
declared by `shared/home/niri.nix`. adeck LM Studio stays declarative (`force = true`); that
host has no UI for those settings. Pi `models.json` stays declarative. `gh`
stays declarative.

## Credentials and reinstalls

The editing copy is `/mnt/echo/nix-os` on adeck; hosts build from `/etc/nixos`.
`secrets/` is ignored by Git. `zcli sync` copies it onto each target's
`/etc/nixos/secrets`; tm20 receives that copy and nothing else. Keep a separate
backup, because a Git clone cannot restore credentials. The rsync below is for
a reinstall, before `zcli` exists on the target.

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
| `pi-openrouter-api-key` | nxiz, adeck, zrrh |
| `festin-openrouter-api-key` | adeck |
| `print-token` | tm20 |
| `hosts/<host>/ssh_host_*` | Matching host, to preserve its SSH identity |
| `nix-access-tokens.conf` | Hosts fetching private Nix inputs; tm20 provisions an empty file |

The staged files keep their original contents, including environment-file
syntax where applicable. `shared/system/secrets.nix` copies required credentials into
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

## What belongs here

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

## What belongs elsewhere

- Shared system behavior belongs in `shared/system/`.
- Shared user behavior belongs in `shared/home/`.
- A module with one importer belongs in that host's directory, under `desk-env/` when it is Home Manager.
- Package pins and overrides belong in `overlays/`. The registry, including when each hold can come off, is `overlays/README.md`.
- Host divergence inside a shared module should usually be a visible `perHost` map keyed by `config.my.host`.

Open the host file, see what the host is made of, then follow imports to the shared policy.
