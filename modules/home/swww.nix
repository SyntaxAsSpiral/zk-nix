# swww — lightweight Wayland wallpaper daemon
# swww img <path> --transition-type fade --transition-duration 1
# swww query — show current wallpaper per output
{ pkgs, ... }:
{
  home.packages = [ pkgs.swww ];

  wayland.windowManager.hyprland.settings."exec-once" = [
    "swww-daemon"
  ];
}
