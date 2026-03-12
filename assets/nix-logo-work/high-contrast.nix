{ pkgs ? import <nixpkgs> {} }:
pkgs.runCommandLocal "nix-logo-high-contrast" { buildInputs = [ pkgs.imagemagick ]; } ''
  mkdir -p $out
  magick -background none -density 600 ${./nix-logo-gradient-high-contrast.svg} -resize 2048x2048 $out/nix-logo-gradient-high-contrast-2048.png
  magick $out/nix-logo-gradient-high-contrast-2048.png -trim +repage $out/nix-logo-gradient-high-contrast-tight.png
''
