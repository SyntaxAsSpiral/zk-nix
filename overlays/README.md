# Overlays and pins

This directory is where package behavior diverges from upstream nixpkgs.

- `default.nix` is the host map. Start there when deciding which host gets an overlay.
- `pins.nix` is for version pins such as Tailscale.
- `patches.nix` is for local `overrideAttrs` fixes such as LM Studio and tumbler.

Current host policy:

- `adeck`: LLM agent overlay, Tailscale pin.
- `nxiz`: CachyOS kernel overlay, Tailscale pin, local package patches.
- `zrrh`: CachyOS kernel overlay, LLM agent overlay, Tailscale pin, local package patches.
