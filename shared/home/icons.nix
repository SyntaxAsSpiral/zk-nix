{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Cursors
    catppuccin-cursors.mochaBlue
    catppuccin-cursors.mochaDark
    catppuccin-cursors.mochaFlamingo
    catppuccin-cursors.mochaGreen
    catppuccin-cursors.mochaLavender
    catppuccin-cursors.mochaLight
    catppuccin-cursors.mochaMaroon
    catppuccin-cursors.mochaMauve
    catppuccin-cursors.mochaPeach
    catppuccin-cursors.mochaPink
    catppuccin-cursors.mochaRed
    catppuccin-cursors.mochaRosewater
    catppuccin-cursors.mochaSapphire
    catppuccin-cursors.mochaSky
    catppuccin-cursors.mochaTeal
    catppuccin-cursors.mochaYellow

    # Installed so nwg-look can switch to it. gtk.nix selects Papirus.
    nordzy-icon-theme

    nwg-look
  ];
}
