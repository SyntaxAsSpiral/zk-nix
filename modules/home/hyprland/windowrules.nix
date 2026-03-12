# Hyprland window rules
{ ... }:

{
  wayland.windowManager.hyprland.settings.windowrule = [
    {
      name = "screensaver-fullscreen";
      "match:class" = "hypr-screensaver";
      fullscreen = true;
      float = true;
    }
    {
      name = "launcher";
      "match:class" = "^(.*launcher.*)$";
      float = true;
      size = "500 430";
      center = true;
      animation = "popin 80%";
    }
    {
      name = "suppress-maximize-events";
      "match:class" = ".*";
      suppress_event = "maximize";
    }
    {
      name = "fix-xwayland-drags";
      "match:class" = "^$";
      "match:title" = "^$";
      "match:xwayland" = true;
      "match:float" = true;
      "match:fullscreen" = false;
      "match:pin" = false;
      no_focus = true;
    }
    {
      name = "move-hyprland-run";
      "match:class" = "hyprland-run";
      move = "20 monitor_h-120";
      float = true;
    }
    {
      name = "firefox-workspace";
      "match:class" = "^(firefox)$";
      workspace = 1;
    }
    {
      name = "spotify-scratchpad";
      "match:class" = "^(spotify)$";
      workspace = "special:magic silent";
    }
    {
      name = "steam-scratchpad";
      "match:class" = "^(steam)$";
      workspace = "special:magic silent";
    }
    {
      name = "lmstudio-scratchpad";
      "match:class" = "^(LM Studio)$";
      workspace = "special:magic silent";
    }
    {
      name = "tui-float";
      "match:class" = "^(tui-float)$";
      float = true;
      center = true;
    }
    {
      name = "gjs";
      "match:class" = "^(gjs)$";
      float = true;
      center = true;
    }
  ];
}
