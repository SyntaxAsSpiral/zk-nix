# The fonts of the esoteric scripts. Tengwar and Aurebesh sit in the private use plane and Maya carries
# the Mayan numerals, so all three are built here from their sources; esoscript.py
# (shared/home/esoscript) is the source of the tables they are built from. The rest of the
# script fonts (the other Aurebesh faces, Quenya, Modern Runic) have no package and are copied
# from assets/esofonts as they are.
{ pkgs, ... }:

let
  assets = ../../assets/esofonts;
  python = pkgs.python3.withPackages (p: [ p.fonttools ]);
  esofonts = pkgs.runCommand "esofonts" { nativeBuildInputs = [ python ]; } ''
    mkdir -p $out/share/fonts
    cp --no-preserve=mode ${assets}/*.otf ${assets}/*.ttf ${assets}/*.TTF $out/share/fonts/
    python ${../../scripts/build-tengwar.py} \
      ${pkgs.unifont}/share/fonts/opentype/unifont/unifont_csur.otf $out/share/fonts \
      ${../../shared/home/esoscript/esoscript.py}
    python ${../../scripts/build-aurebesh.py} ${assets}/Aurebesh.otf $out/share/fonts
    python ${../../scripts/build-maya-numerals.py} ${assets}/Maya.otf \
      ${pkgs.noto-fonts}/share/fonts/noto/NotoSansMayanNumerals-Regular.otf $out/share/fonts/Maya.otf
  '';
in
{
  fonts.packages = [ esofonts ];
}
