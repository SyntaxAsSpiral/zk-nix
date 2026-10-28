# Esoteric fonts

The fonts in this directory are checked into the flake and installed
declaratively by `shared/nixos/fonts.nix`. The module copies this directory into a
Nix font package, so no manual copy or `fc-cache` step is required.

It currently includes Mayan, Aurebesh, Tengwar/Quenya, runic, Symbola, and
other display fonts. The complete installed font set, including fonts supplied
by nixpkgs, is defined in `shared/nixos/fonts.nix`; keep this file focused on the
checked-in asset directory.
