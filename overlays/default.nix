{ inputs, system ? "x86_64-linux" }:

let
  nixpkgsFixes = import ./nixpkgs-fixes.nix;
  flakePackages = import ./flake-packages.nix { inherit inputs system; };
  pins = import ./pins.nix;

  fromInputs = {
    cachyosKernel = inputs.nix-cachyos-kernel.overlays.pinned;
    # Upstream dropped overlays.default; shared-nixpkgs is pkgs.llm-agents.*.
    llmAgents = inputs.llm-agents.overlays.shared-nixpkgs;
  };
in
{
  inherit fromInputs nixpkgsFixes flakePackages pins;

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
  };
}