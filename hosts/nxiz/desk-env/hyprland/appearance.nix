# Hyprland visual config: layout, decoration, animations
{ config, ... }:

let
  p = config.colorScheme.palette;
in
{
  wayland.windowManager.hyprland.settings = {
    general = {
      gaps_in      = 15;
      gaps_out     = 20;
      border_size  = 2;
      "col.active_border"   = "rgb(cba6f7) rgb(89b4fa) rgb(94e2d5) rgb(f5e0dc) rgb(f2cdcd) rgb(eba0ac) 45deg";
      "col.inactive_border" = "rgb(${p.base02})";
      resize_on_border = true;
      allow_tearing    = false;
      layout           = "dwindle";
    };

    decoration = {
      rounding        = 10;
      rounding_power  = 2;
      active_opacity   = 1.0;
      inactive_opacity = 0.8;
      shadow = {
        enabled      = true;
        range        = 4;
        render_power = 3;
        color        = "rgb(${p.base00})";
      };

      dim_inactive = true;
      dim_strength = 0.1;
      dim_special  = 0.2;

      blur = {
        enabled  = true;
        size     = 3;
        passes   = 1;
        vibrancy = 0.1696;
        xray     = true;
        special  = true;
      };
    };

    misc = {
      force_default_wallpaper  = 0;
      disable_hyprland_logo    = true;
      disable_splash_rendering = false;
      font_family              = "RecMonoCasual Nerd Font";
      splash_font_family       = "Recursive";
    };

    dwindle = {
      preserve_split       = true;
      special_scale_factor = 0.8;
    };

    master = {
      new_status = "master";
    };

    animations = {
      enabled = "yes, please :)";
      bezier = [
        "easeOutQuint,   0.23, 1,    0.32, 1"
        "easeInOutCubic, 0.65, 0.05, 0.36, 1"
        "linear,         0,    0,    1,    1"
        "almostLinear,   0.5,  0.5,  0.75, 1"
        "quick,          0.15, 0,    0.1,  1"
      ];
      animation = [
        "global,           1,  10,    default"
        "border,           1,   5.39, easeOutQuint"
        "windows,          1,   4.79, easeOutQuint"
        "windowsIn,        1,   4.1,  easeOutQuint, popin 87%"
        "windowsOut,       1,   1.49, linear,       popin 87%"
        "fadeIn,            1,   1.73, almostLinear"
        "fadeOut,           1,   1.46, almostLinear"
        "fade,             1,   3.03, quick"
        "layers,           1,   3.81, easeOutQuint"
        "layersIn,         1,   4,    easeOutQuint, fade"
        "layersOut,        1,   1.5,  linear,       fade"
        "fadeLayersIn,     1,   1.79, almostLinear"
        "fadeLayersOut,    1,   1.39, almostLinear"
        "specialWorkspace, 1,   4,    easeOutQuint, slidevert"
        "workspaces,       1,   1.94, almostLinear, fade"
        "workspacesIn,     1,   1.21, almostLinear, fade"
        "workspacesOut,    1,   1.94, almostLinear, fade"
        "zoomFactor,       1,   7,    quick"
      ];
    };
  };

  # hyprpaper is not used. nxiz wallpapers come from awww.
}
