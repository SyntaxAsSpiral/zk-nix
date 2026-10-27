{ pkgs, ... }:

{
  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty;
    settings = {
      font-family = "RecMonoCasual Nerd Font Mono";
      font-size = 12;
      background-opacity = 0.92;
      window-padding-x = 8;
      window-padding-y = 8;
      command = "${pkgs.nushell}/bin/nu";
      window-decoration = true;
      theme = "Rose Pine Moon";
    };
  };
}
