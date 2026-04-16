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

  systemd.user.services.llmster = {
    Unit = {
      Description = "LM Studio Headless Server (llmster)";
      After = [ "network.target" ];
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
    Service = {
      ExecStart = "${llmster}/bin/llmster";
      Restart = "always";
      RestartSec = "10";
      # The bundle needs access to standard node/v8 environment, usually standard with user services
      Environment = "HOME=%h";
    };
  };
}
