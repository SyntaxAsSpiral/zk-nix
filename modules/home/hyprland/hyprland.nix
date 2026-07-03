# Hyprland compositor core — variables, exec-once, and module imports
{ pkgs, ... }:
{
  # TODO(lua migration): configType="lua" is intended but blocked — the
  # auto-translation mangles `$var` settings into invalid Lua (hl.$browser(...)).
  # Port every $var to `_var` form first. Warning left unsilenced on purpose.

  imports = [
    ./keybinds.nix
    ./windowrules.nix
    ./monitors.nix
    ./appearance.nix
    ./hypridle.nix
    ./hyprpanel.nix
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
  ];

  services.hyprpolkitagent.enable = true;

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$terminal" = "kitty";
      "$fileManager" = "kitty --class tui-float -e yazi";
      "$menu" = "kitty --class launcher -e fsel -d";
      "$search" = "kitty --class launcher -e otter-launcher";
      "$browser" = "firefox";
      "$editor" = "zeditor";
      "$editor-alt" = "kitty --class tui-float -e nano";
      "$notes" = "obsidian";
      "$mainMod" = "SUPER";
      "$screensaver" =
        "bash -c 'for ws in $(hyprctl monitors -j | jq -r \".[].activeWorkspace.id\"); do hyprctl dispatch exec \"[fullscreen;silent;workspace:$ws] kitty --class hypr-screensaver -e neo --colormode=32 -C ~/.config/neo/frappe-sapphire.cfg\"; done'";

      cursor = {
        no_hardware_cursors = true;
      };

      env = [
        "XCURSOR_SIZE,30"
        "HYPRCURSOR_SIZE,30"
        "XCURSOR_THEME,catppuccin-mocha-blue-cursors"
        "HYPRCURSOR_THEME,catppuccin-mocha-blue-cursors"
        "TZDIR,/etc/zoneinfo"
      ];

      "exec-once" = [
        "gnome-keyring-daemon --start --components=secrets,ssh"
        "hyprpanel"
      ];
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
    icon_theme             = Tela-circle-dracula
    big_rounding           = 12
    small_rounding         = 8
  '';
}
