# awww, a lightweight Wayland wallpaper daemon.
# awww img <path> --transition-type fade --transition-duration 1
# awww query: show the current wallpaper per output.
{ pkgs, ... }:
{
  # awww-daemon is started from hyprland/lua/hyprland.lua.
  home.packages = [ pkgs.awww ];
}
