# Hyprland compositor core. The config is hand-written Lua in ./lua: hyprland.lua is the
# entry file (variables, env, autostart) and requires monitors, appearance, windowrules and
# keybinds. home-manager's own settings-to-Lua translation is not used.
{ pkgs, ... }:
{
  imports = [
    ./hypridle.nix
  ];

  home.packages = with pkgs; [
    qt5.qtwayland
    qt6.qtwayland
    wl-clipboard
    grim
    slurp
    swappy
    hyprshot
    libnotify
    bemoji
    rofi
    wtype
    playerctl

    # HyprPanel and the helpers its dashboard calls.
    hyprpanel
    wf-recorder
    matugen
    awww
  ];

  services.hyprpolkitagent.enable = true;

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    extraConfig = builtins.readFile ./lua/hyprland.lua;
    # autoLoad is off: hyprland.lua requires these itself, after it sets the shared variables.
    extraLuaFiles = {
      monitors = {
        content = ./lua/monitors.lua;
        autoLoad = false;
      };
      appearance = {
        content = ./lua/appearance.lua;
        autoLoad = false;
      };
      windowrules = {
        content = ./lua/windowrules.lua;
        autoLoad = false;
      };
      keybinds = {
        content = ./lua/keybinds.lua;
        autoLoad = false;
      };
    };
  };

  xdg.configFile."hypr/hyprtoolkit.conf".text = ''
    background       = 0xee303446
    base             = 0xff303446
    alternate_base   = 0xff414559
    text             = 0xffc6d0f5
    bright_text      = 0xfff2d5cf
    link_text        = 0xff74c7ec
    accent           = 0xff74c7ec
    accent_secondary = 0xff85c1dc

    font_family            = RecMonoCasual Nerd Font
    font_family_monospace  = RecMonoCasual Nerd Font Mono
    icon_theme             = Papirus-Dark
    big_rounding           = 12
    small_rounding         = 8
  '';
}
