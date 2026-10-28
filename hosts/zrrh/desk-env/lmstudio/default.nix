{ config, lib, pkgs, ... }:

let
  home = config.home.homeDirectory;
  unhook = import ../../../../shared/home/unhook-etc-nixos.nix;
in
{
  imports = [ ../../../../shared/home/lmstudio/log-retention.nix ];

  # LM Studio on zrrh. The package provides the binary. Settings, presets,
  # and the http server config are copied out of /etc/nixos once, then LM Studio owns them.
  home.activation.lmstudioConfigZrrh = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.lmstudio" "$HOME/.lmstudio/models" "$HOME/.lmstudio/hub/models" "$HOME/.lmstudio/bin" "$HOME/.lmstudio/.internal"
    ${unhook {
      inherit lib;
      paths = [
        "${home}/.lmstudio/settings.json"
        "${home}/.lmstudio/config-presets"
        "${home}/.lmstudio/.internal/http-server-config.json"
      ];
    }}
  '';

  # Full GUI install: CUDA detection and `lms` CLI attach to this process.
  # niri spawn-at-startup is fire-and-forget and misses some boots.
  systemd.user.services.lmstudio = {
    Unit = {
      Description = "LM Studio";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.lmstudio}/bin/lm-studio --hidden";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
