# Overlays and pins

This directory is where package behavior diverges from upstream nixpkgs and flake inputs.

- `default.nix` is the host map. Start here when deciding which host gets an overlay.
- `pins.nix` is for version pins such as Tailscale.
- `nixpkgs-fixes.nix` is for local `overrideAttrs` fixes on nixpkgs packages (e.g. LM Studio, tumbler).
- `flake-packages.nix` wraps flake-input packages with local patches (e.g. fsel).
- `patches/` holds `.patch` files referenced from overlay code.

Current host policy:

- `adeck`: LLM agent overlay, Tailscale pin, flake-input package patches.
- `nxiz`: CachyOS kernel overlay, Tailscale pin, nixpkgs fixes, flake-input package patches.
- `zrrh`: CachyOS kernel overlay, LLM agent overlay, Tailscale pin, nixpkgs fixes.