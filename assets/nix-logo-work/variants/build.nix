{ pkgs ? import <nixpkgs> {} }:
let
  names = [
    "vivid-pairs"
    "esotericon-opposed"
    "sunset-forge"
    "prism-bloom"
  ];
in pkgs.runCommandLocal "nix-logo-variant-pack" { buildInputs = [ pkgs.imagemagick ]; } ''
  mkdir -p $out
  ${builtins.concatStringsSep "\n" (map (n: ''
    magick -background none -density 600 ${./.}/${n}.svg -resize 2048x2048 $out/${n}-2048.png
    magick $out/${n}-2048.png -trim +repage $out/${n}-tight.png
  '') names)}
''
