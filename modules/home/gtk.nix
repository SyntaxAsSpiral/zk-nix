{ config, pkgs, ... }:

{
  # GTK theme
  gtk = {
    enable = true;
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.theme = config.gtk.theme; # Keep legacy default (inherit from gtk.theme)
    theme = {
      name = "Catppuccin-Purple-Dark-Catppuccin";
      package = null; # provided via home.file
    };
    iconTheme = {
      name = "Tela-circle-dracula";
      package = null; # provided via home.file
    };
  };

  # Force dark mode for GTK apps
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  home.packages = with pkgs; [
    nwg-look
    dconf
  ];

  home.file = {
    ".themes/Catppuccin-Purple-Dark-Catppuccin".source =
      ../../assets/gtk-themes/Catppuccin-Purple-Dark-Catppuccin;
  };
}
