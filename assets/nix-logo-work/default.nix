{ pkgs ? import <nixpkgs> {} }:
pkgs.runCommandLocal "nix-logo-assets" { buildInputs = [ pkgs.imagemagick ]; } ''
  mkdir -p $out
  magick -background none -density 600 ${./nix-logo-gradient.svg} -resize 2048x2048 $out/nix-logo-gradient-2048.png
  magick -background none -density 600 ${./nix-logo-solid.svg} -resize 2048x2048 $out/nix-logo-solid-2048.png
  magick $out/nix-logo-gradient-2048.png -trim +repage $out/nix-logo-gradient-tight.png
  magick $out/nix-logo-solid-2048.png -trim +repage $out/nix-logo-solid-tight.png
''
