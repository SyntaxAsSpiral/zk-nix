{
  pkgs ? import <nixpkgs> { },
}:
pkgs.runCommandLocal "nix-logo-mocha-pairs" { buildInputs = [ pkgs.imagemagick ]; } ''
  mkdir -p $out
  magick -background none -density 600 ${./nix-logo-gradient-mocha-pairs.svg} -resize 2048x2048 $out/nix-logo-gradient-mocha-pairs-2048.png
  magick $out/nix-logo-gradient-mocha-pairs-2048.png -trim +repage $out/nix-logo-gradient-mocha-pairs-tight.png
''
