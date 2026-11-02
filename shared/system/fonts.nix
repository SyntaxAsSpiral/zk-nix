# System fonts, on every host through core.nix. The fonts of the esoteric scripts are in esofonts.nix.
{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    nerd-fonts.recursive-mono
    nerd-fonts.victor-mono
   # ibm-plex
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
    kode-mono
    miracode
    (google-fonts.override {
      fonts = [
        "Syne Mono"
        "Nova Mono"
        "Aladin"
        "Amarante"
        "Aubrey"
        "Combo"
        "Faculty Glyphic"
        "Glass Antiqua"
        "Spicy Rice"
        "Viaoda Libre"
        # IM Fell English, under the file names Google ships it as
        "IMFeENrm28P"
        "IMFeENit28P"
      ];
    })
  ];

  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [ "RecMonoCasual Nerd Font" "DejaVu Sans Mono" ];
      sansSerif = [ "Noto Sans" ];
      serif = [ "RecMonoCasual Nerd Font" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
