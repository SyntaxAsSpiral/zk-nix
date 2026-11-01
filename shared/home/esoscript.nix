# esoscript: text in the esoteric scripts of the greek-to-me mod (greek, runic, braille, klingon,
# quenya, tengwar, hebrew, katakana, malayalam, arabic, grimdark, hiero, aurebesh, maya). The shell
# kit's, on every host through the otter imports. The private use scripts (aurebesh, maya, tengwar,
# quenya, klingon) are drawn by the fonts in assets/esofonts, which shared/system/fonts.nix installs.
{ pkgs, ... }:

let
  esoscript = pkgs.writeShellApplication {
    name = "esoscript";
    text = ''exec ${pkgs.python3}/bin/python3 -I ${./esoscript/esoscript.py} "$@"'';
  };
in
{
  home.packages = [ esoscript ];
}
