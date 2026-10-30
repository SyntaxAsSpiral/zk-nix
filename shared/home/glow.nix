# glow's config file reads width 0 as unset, so the defaults ride as flags on a wrapper. Every call
# gets them, the otter modules included, and a flag typed on the command line still overrides.
# Extra styles sit in ~/.config/glow/styles. glow takes a style by path: glow -s ~/.config/glow/styles/x.json
{ lib, pkgs, ... }:
let
  catppuccin = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "glamour";
    rev = "00c97fa3823d272d9d041d5d872ae6335555a776";
    hash = "sha256-SI/COnVFdKltMRqeqLTbR/Rh0xUJcWSqiX/YlR221eo=";
  };
  tomorrowNight = pkgs.fetchFromGitHub {
    owner = "gbraad";
    repo = "glow-glamour-tomorrownightbright";
    rev = "b187a676dea59d2b886c6cac770b772db5504973";
    hash = "sha256-nrlwaUUDlIc0zsShkjEhs7V04YrLvIbDFqYqIUHu6p4=";
  };

  # File name under ~/.config/glow/styles, and where it sits in its repo.
  styles = {
    "catppuccin-frappe.json" = "${catppuccin}/themes/catppuccin-frappe.json";
    "catppuccin-latte.json" = "${catppuccin}/themes/catppuccin-latte.json";
    "catppuccin-macchiato.json" = "${catppuccin}/themes/catppuccin-macchiato.json";
    "catppuccin-mocha.json" = "${catppuccin}/themes/catppuccin-mocha.json";
    "tomorrow-night-bright.json" = "${tomorrowNight}/tomorrownightbright.json";

    # Editable copies: Macchiato as the Catppuccin base, and Rosé Pine Moon. Change these, not upstream.
    "catppuccin-macchiato-custom.json" = ./glow-styles/catppuccin-macchiato-custom.json;
    "rose-pine-moon-custom.json" = ./glow-styles/rose-pine-moon-custom.json;
    "nord-custom.json" = ./glow-styles/nord-custom.json;

    # ANSI palette numbers only, so it follows the terminal. Chroma takes hex alone, so code blocks have no syntax colours.
    "ansi-custom.json" = ./glow-styles/ansi-custom.json;
  };
in
{
  home.packages = [
    (pkgs.symlinkJoin {
      name = "glow";
      paths = [ pkgs.glow ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''wrapProgram $out/bin/glow --add-flags "--style ${./glow-styles/rose-pine-moon-custom.json} -w 0 -n -l"'';
    })
  ];

  xdg.configFile = lib.mapAttrs' (
    name: source: lib.nameValuePair "glow/styles/${name}" { inherit source; }
  ) styles;
}
