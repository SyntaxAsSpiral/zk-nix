{ config, pkgs, ... }:

let
  llmster = pkgs.callPackage ./llmster-bin/package.nix { };
in
{
  # LM Studio config for adeck.
  home.packages = [ llmster ];
  # System package (pkgs.lmstudio) handles binaries and services.
  home.activation.ensureLmstudioDirsAdeck = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.lmstudio" "$HOME/.lmstudio/models" "$HOME/.lmstudio/hub/models" "$HOME/.lmstudio/bin" "$HOME/.lmstudio/.internal"
  '';

  home.file.".lmstudio/settings.json".source = ./settings.json;
  home.file.".lmstudio/config-presets".source = ../config-presets;
  home.file.".lmstudio/.internal/http-server-config.json".source = ./http-server-config.json;
}
