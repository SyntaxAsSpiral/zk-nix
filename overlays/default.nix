{
  inputs,
  system ? "x86_64-linux",
}:

let
  nixpkgsFixes = import ./nixpkgs-fixes.nix;
  flakePackages = import ./flake-packages.nix { inherit inputs system; };

  fromInputs = {
    cachyosKernel = inputs.nix-cachyos-kernel.overlays.pinned;
    hyprland = _final: _prev: {
      hyprland = inputs.nixpkgs-hyprland.legacyPackages.${system}.hyprland;
    };
    openrgb = _final: _prev: {
      openrgb-with-all-plugins = inputs.nixpkgs-openrgb.legacyPackages.${system}.openrgb-with-all-plugins;
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
    ;

  # Host overlay map. Edit this first when a package override/pin should apply
  # to one mesh host but not another.
  hosts = {
    adeck = [
      fromInputs.llmAgents
    ]
    ++ flakePackages;

    nxiz = [
      fromInputs.cachyosKernel
      fromInputs.hyprland
    ]
    ++ nixpkgsFixes
    ++ flakePackages;

    zrrh = [
      fromInputs.cachyosKernel
      fromInputs.llmAgents
      fromInputs.openrgb
    ]
    ++ nixpkgsFixes;

    tm20 = [
      (import ./tm20-cli.nix { inherit inputs; })
    ];

    # Rescue stick: stock nixpkgs kernel and packages, all from cache.nixos.org.
    seed = [ ];
  };
}
