{ inputs }:

let
  patches = import ./patches.nix;
  pins = import ./pins.nix;

  fromInputs = {
    cachyosKernel = inputs.nix-cachyos-kernel.overlays.pinned;
    llmAgents = inputs.llm-agents.overlays.default;
  };
in
{
  inherit fromInputs patches pins;

  # Host overlay map. Edit this first when a package override/pin should apply
  # to one mesh host but not another.
  hosts = {
    adeck = [
      fromInputs.llmAgents
      pins.tailscale
    ];

    nxiz = [
      fromInputs.cachyosKernel
      pins.tailscale
    ]
    ++ patches;

    zrrh = [
      fromInputs.cachyosKernel
      fromInputs.llmAgents
      pins.tailscale
    ]
    ++ patches;
  };
}
