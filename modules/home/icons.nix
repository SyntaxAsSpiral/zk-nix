{ pkgs, ... }:

{
  home.file = {
    ".icons/Tela-circle-dracula".source = ../../assets/icons/Tela-circle-dracula;
    ".local/share/icons/Tela-circle-dracula".source = ../../assets/icons/Tela-circle-dracula;
  };

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

    # Icons
    nordzy-icon-theme
  ];
}
