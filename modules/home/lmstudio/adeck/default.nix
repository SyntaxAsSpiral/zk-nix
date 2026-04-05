{ config, pkgs, ... }:

{
  # LM Studio on adeck: llmster only (no GUI/AppImage) via nixpkgs.
  home.activation.ensureLmstudioDirsAdeck = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.lmstudio" "$HOME/.lmstudio/models" "$HOME/.lmstudio/hub/models" "$HOME/.lmstudio/.internal"
  '';

  home.file.".lmstudio/settings.json".source = ./settings.json;
  home.file.".lmstudio/config-presets".source = ../config-presets;
  home.file.".lmstudio/.internal/http-server-config.json".source = ./http-server-config.json;

  # Start llmster daemon on boot
  systemd.user.services.llmster = {
    Unit = {
      Description = "LM Studio daemon (llmster)";
      After = [ "network-online.target" ];
    };
    Service = {
      Type = "forking";
      ExecStart = "${pkgs.lmstudio}/bin/lms daemon up";
      ExecStop = "${pkgs.lmstudio}/bin/lms daemon down";
      TimeoutStopSec = "20s";
      KillMode = "control-group";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
