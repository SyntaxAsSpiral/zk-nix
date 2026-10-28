{ config, lib, pkgs, ... }:

let
  home = config.home.homeDirectory;
  unhook = import ../../../../shared/home/unhook-etc-nixos.nix;
in
{
  # LM Studio on nxiz. The package provides the binary. Settings, presets,
  # and the http server config are copied out of /etc/nixos once, then LM Studio owns them.
  home.activation.lmstudioConfigNxiz = config.lib.dag.entryAfter [ "writeBoundary" ] ''
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

  systemd.user.services.lmstudio = {
    Unit = {
      Description = "LM Studio";
      After = [ "hyprland-session.target" ];
      PartOf = [ "hyprland-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.lmstudio}/bin/lm-studio";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };
}
