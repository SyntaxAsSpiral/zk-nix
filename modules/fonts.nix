# All fonts: system + esoteric
{ pkgs, ... }:

let
  esofontsSrc = ../assets/esofonts;
in
{
  fonts.packages =
    with pkgs;
    [
      nerd-fonts.jetbrains-mono
      nerd-fonts.iosevka
      nerd-fonts.fira-code
      nerd-fonts.victor-mono
      nerd-fonts.ubuntu-mono
      nerd-fonts.recursive-mono
      cascadia-code
      ibm-plex
      cinzel
      eb-garamond
      cardo
      nerd-fonts.symbols-only
      symbola
      font-awesome
      noto-fonts-color-emoji
      noto-fonts
      noto-fonts-cjk-sans
      liberation_ttf
      vt323
    ]
    ++ [
      # Esoteric fonts from assets
      (pkgs.runCommand "esofonts" { } ''
        mkdir -p $out/share/fonts
        cp -r ${esofontsSrc}/* $out/share/fonts/
      '')
    ];

  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [
        "RecMonoCasual Nerd Font"
        "JetBrainsMono Nerd Font"
      ];
      sansSerif = [ "Noto Sans" ];
      serif = [ "RecMonoCasual Nerd Font" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
