# Hyprland keybindings — bind/bindm/bindel/bindl
_:

{
  wayland.windowManager.hyprland.settings = {
    bind = [

      "$mainMod, Q, exec, $terminal"
      "$mainMod, W, togglefloating,"
      "$mainMod, E, exec, $editor"
      "$mainMod SHIFT, E, exec, $editor-alt"
      "$mainMod, R, exec, $menu"

      "$mainMod, A, exec, $search"
      "$mainMod, S, togglespecialworkspace, magic"
        "$mainMod SHIFT, S, movetoworkspace, special:magic"
      "$mainMod, D, layoutmsg, togglesplit"
      "$mainMod, F, fullscreen, 1" # maximize
        "$mainMod SHIFT, F, fullscreen, 0"

      "$mainMod, Z, exec, $notes"
      "$mainMod, X, killactive,"
      "$mainMod, C, pseudo,"
      "$mainMod, V, exec, $fileManager"

      "$mainMod, B, exec, $browser"
      "$mainMod, P, exec, hyprpicker -a" # troubleshooting needed
      "$mainMod, M, exec, hyprpanel -q; hyprpanel"
        "$mainMod SHIFT, M, exec, hyprctl dispatch exit"      
      "$mainMod, period, exec, kitty --class tui-float --title otter-launcher -e otter-launcher em"
      "$mainMod, DELETE, exec, kitty --class tui-float -e btop"

      # Screenshots
      ", Print, exec, hyprshot -m output -o ~/Images/Screenshots"
      "$mainMod, Home, exec, hyprshot -z -m region -o ~/Images/Screenshots"

      # Focus
      "$mainMod, left, movefocus, l"
      "$mainMod, right, movefocus, r"
      "$mainMod, up, movefocus, u"
      "$mainMod, down, movefocus, d"

      # Scratchpad


      # Workspaces
      "$mainMod, 1, workspace, 1"
      "$mainMod, 2, workspace, 2"
      "$mainMod, 3, workspace, 3"
      "$mainMod, 4, workspace, 4"
      "$mainMod, 5, workspace, 5"
      "$mainMod, 6, workspace, 6"
      "$mainMod, 7, workspace, 7"
      "$mainMod, 8, workspace, 8"
      "$mainMod, 9, workspace, 9"
      "$mainMod, 0, workspace, 10"

      # Move to workspace
      "$mainMod SHIFT, 1, movetoworkspace, 1"
      "$mainMod SHIFT, 2, movetoworkspace, 2"
      "$mainMod SHIFT, 3, movetoworkspace, 3"
      "$mainMod SHIFT, 4, movetoworkspace, 4"
      "$mainMod SHIFT, 5, movetoworkspace, 5"
      "$mainMod SHIFT, 6, movetoworkspace, 6"
      "$mainMod SHIFT, 7, movetoworkspace, 7"
      "$mainMod SHIFT, 8, movetoworkspace, 8"
      "$mainMod SHIFT, 9, movetoworkspace, 9"
      "$mainMod SHIFT, 0, movetoworkspace, 10"

      # Scroll workspaces
      "$mainMod, mouse_down, workspace, e+1"
      "$mainMod, mouse_up, workspace, e-1"
    ];

    bindm = [
      "$mainMod, mouse:272, movewindow"
      "$mainMod, mouse:273, resizewindow"
    ];

    bindel = [
      ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
      ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
    ];

    bindl = [
      ", XF86AudioNext, exec, playerctl next"
      ", XF86AudioPause, exec, playerctl play-pause"
      ", XF86AudioPlay, exec, playerctl play-pause"
      ", XF86AudioPrev, exec, playerctl previous"
    ];
  };
}
