{ config, pkgs, inputs, ... }:

{
  home.packages = [
    inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # Mutable symlinks — hermes rewrites its config, so we force link to the repo.
  # The repo is stored at /etc/nixos on adeck.
  home.activation.hermesConfig = config.lib.dag.entryAfter [ "linkGeneration" ] ''
    mkdir -p ${config.home.homeDirectory}/.hermes
    ln -sf /etc/nixos/modules/home/daemonturgy/hermes/config.yaml ${config.home.homeDirectory}/.hermes/config.yaml
    ln -sf /etc/nixos/modules/home/daemonturgy/hermes/SOUL.md ${config.home.homeDirectory}/.hermes/SOUL.md
  '';
}
