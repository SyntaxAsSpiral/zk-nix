{ pkgs, ... }:

let
  # build.py takes one flavor per run and any number of accents.
  # A theme dir is catppuccin-<flavor>-<accent>-standard+normal.
  accents = [
    "mauve"
    "sapphire"
    "maroon"
    "teal"
  ];
  gtkTheme = flavor: pkgs.catppuccin-gtk.override {
    variant = flavor;
    inherit accents;
    size = "standard";
    tweaks = [ "normal" ];
  };
  macchiato = gtkTheme "macchiato";
  frappe = gtkTheme "frappe";
  themeName = "catppuccin-macchiato-mauve-standard+normal";
  icons = pkgs.catppuccin-papirus-folders.override {
    flavor = "macchiato";
    accent = "mauve";
  };
in
{
  # The other seven themes are on the picker. A switch puts this name back.
  # The same switch replaces gtk.css when nwg-look or an app has rewritten it.
  home.packages = [ frappe ];

  xdg.configFile."gtk-4.0/gtk.css".force = true;

  gtk = {
    enable = true;
    colorScheme = "dark";
    theme = {
      name = themeName;
      package = macchiato;
    };
    gtk4.theme = {
      name = themeName;
      package = macchiato;
    };
    # Papirus with mauve folders. A switch rewrites this, so an nwg-look
    # icon pick lasts until the next switch. Nordzy stays installed.
    iconTheme = {
      name = "Papirus-Dark";
      package = icons;
    };
  };
}
