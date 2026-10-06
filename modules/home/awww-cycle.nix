# awww daemon + 10-minute random cycle for niri/graphical-session hosts.
# Hyprland hosts keep using awww.nix (exec-once) instead.
{ config, pkgs, ... }:
let
  cycle = pkgs.writeShellApplication {
    name = "awww-cycle";
    runtimeInputs = [
      pkgs.awww
      pkgs.findutils
      pkgs.coreutils
    ];
    text = ''
      dir="${config.home.homeDirectory}/Images/wallpapers"
      i=0
      while ! awww query >/dev/null 2>&1; do
        i=$((i + 1))
        [ "$i" -lt 15 ]
        sleep 1
      done
      img=$(find -L "$dir" \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | shuf -n1)
      [ -n "$img" ]
      awww img "$img" --transition-type fade --transition-duration 1
    '';
  };
in
{
  home.packages = [
    pkgs.awww
    cycle
  ];

  systemd.user = {
    services.awww = {
      Unit = {
        Description = "awww wallpaper daemon";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.awww}/bin/awww-daemon";
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    services.awww-cycle = {
      Unit = {
        Description = "Set a random wallpaper";
        After = [ "awww.service" ];
        Requires = [ "awww.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${cycle}/bin/awww-cycle";
      };
    };

    timers.awww-cycle = {
      Unit.Description = "Cycle wallpaper every 10 minutes";
      Timer = {
        OnStartupSec = "3s";
        OnUnitActiveSec = "10m";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
