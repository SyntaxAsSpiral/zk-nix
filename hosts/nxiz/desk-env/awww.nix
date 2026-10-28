# awww (née swww) — lightweight Wayland wallpaper daemon
# awww img <path> --transition-type fade --transition-duration 1
# awww query — show current wallpaper per output
{ pkgs, ... }:
{
  home.packages = [ pkgs.awww ];

  wayland.windowManager.hyprland.settings."exec-once" = [
    "awww-daemon"
  ];
}
