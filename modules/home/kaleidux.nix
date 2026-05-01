# Kaleidux — dynamic wallpaper daemon (video + GLSL transitions)
# kldctl next/prev/query/love/pause/resume/reload/kill
{ config, pkgs, inputs, ... }:
{
  home.packages = [
    inputs.kaleidux.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  xdg.configFile."kaleidux/config.toml".text = ''
    [global]
    monitor-behavior = "independent"
    sorting = "random"

    [any]
    path = "${config.home.homeDirectory}/Images/wallpapers"
    duration = "10m"
    video-ratio = 0
    transition = { type = "fade", duration = 800 }
  '';

  # Daemon as systemd user service — compositor-agnostic
  systemd.user.services.kaleidux = {
    Unit = {
      Description = "Kaleidux wallpaper daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${inputs.kaleidux.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/kaleidux-daemon";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
