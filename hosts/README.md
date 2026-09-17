# Hosts

Host files are the table of contents for each machine.

`tm20` is the Pi 3B+ print-host appliance: it does **not** import `profiles/core.nix` or Home-Manager. First boot is an sdImage (`zcli image tm20`), not a systemd-boot desktop install.

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
- Package pins and overrides belong in `overlays/`.
- Host divergence inside a shared module should usually be a visible `perHost` map keyed by `config.my.host`.

The goal is not fewer lines. The goal is fast orientation: open the host file, see what the host is made of, then follow imports to the shared policy.
