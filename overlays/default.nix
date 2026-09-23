{
  inputs,
  system ? "x86_64-linux",
}:

let
  nixpkgsFixes = import ./nixpkgs-fixes.nix;
  flakePackages = import ./flake-packages.nix { inherit inputs system; };
  pins = import ./pins.nix;

  fromInputs = {
    cachyosKernel = inputs.nix-cachyos-kernel.overlays.pinned;
    hyprland = _final: _prev: {
      hyprland = inputs.nixpkgs-hyprland.legacyPackages.${system}.hyprland;
    };
    # Upstream dropped overlays.default; shared-nixpkgs is pkgs.llm-agents.*.
    llmAgents = inputs.llm-agents.overlays.shared-nixpkgs;
  };
in
{
  inherit
    fromInputs
    nixpkgsFixes
    flakePackages
    pins
    ;

  # Host overlay map. Edit this first when a package override/pin should apply
  # to one mesh host but not another.
  hosts = {
    adeck = [
      fromInputs.llmAgents
      pins.tailscale
    ]
    ++ flakePackages;

    nxiz = [
      fromInputs.cachyosKernel
      fromInputs.hyprland
      pins.tailscale
    ]
    ++ nixpkgsFixes
    ++ flakePackages;

    zrrh = [
      fromInputs.cachyosKernel
      fromInputs.llmAgents
      pins.tailscale
    ]
    ++ nixpkgsFixes;

    tm20 = [
      pins.tailscale
      (import ./tm20-cli.nix { inherit inputs; })
    ];
  };
}
