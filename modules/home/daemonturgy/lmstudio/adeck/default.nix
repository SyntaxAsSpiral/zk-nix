{ config, pkgs, ... }:

let
  llmster = pkgs.callPackage ./llmster-bin/package.nix { };
in
{
  # LM Studio config for adeck.
  home.packages = [ llmster ];
  # System package (pkgs.lmstudio) handles binaries and services.
  # Ensure directories and seed settings imperatively so LM Studio can write to them
  home.activation.ensureLmstudioDirsAdeck = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.lmstudio" "$HOME/.lmstudio/models" "$HOME/.lmstudio/hub/models" "$HOME/.lmstudio/bin" "$HOME/.lmstudio/.internal"
    # Seed settings.json imperatively so it remains fully writable (not a Nix store symlink)
    cp ${./settings.json} "$HOME/.lmstudio/settings.json"
    chmod 644 "$HOME/.lmstudio/settings.json"
  '';

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
