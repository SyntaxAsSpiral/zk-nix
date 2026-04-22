{ config, pkgs, ... }:

let
  llmster = pkgs.callPackage ./llmster-bin/package.nix { };
in
{
  # LM Studio config for adeck.
  home.packages = [ llmster ];
  # System package (pkgs.lmstudio) handles binaries and services.
  # Mutable symlinks for LMStudio — LMStudio writes its config, so we force link to the repo.
  home.activation.lmstudioConfigAdeck = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.lmstudio" "$HOME/.lmstudio/models" "$HOME/.lmstudio/hub/models" "$HOME/.lmstudio/bin" "$HOME/.lmstudio/.internal"
    ln -sfT /etc/nixos/modules/home/daemonturgy/lmstudio/adeck/settings.json ${config.home.homeDirectory}/.lmstudio/settings.json
    ln -sfT /etc/nixos/modules/home/daemonturgy/lmstudio/config-presets ${config.home.homeDirectory}/.lmstudio/config-presets
    ln -sfT /etc/nixos/modules/home/daemonturgy/lmstudio/adeck/http-server-config.json ${config.home.homeDirectory}/.lmstudio/.internal/http-server-config.json
  '';

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
