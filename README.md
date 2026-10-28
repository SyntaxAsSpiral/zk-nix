# zk-nix

NixOS flake for the zk Tailscale mesh.

- [shared/README.md](shared/README.md) says where a leaf module goes.
- [hosts/README.md](hosts/README.md) says what each machine imports, which app configs are unhooked, and which credentials a reinstall needs.
- [overlays/README.md](overlays/README.md) is the registry of pins and package holds, and when each one comes off.
- [shared/home/pi/README.md](shared/home/pi/README.md) is the Pi agent's local model list.
- [assets/esofonts/README.md](assets/esofonts/README.md) is the checked-in display fonts that `shared/system/fonts.nix` installs.

Rules for editing the flake are in [AGENTS.md](AGENTS.md).
