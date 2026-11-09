# adeck terminal. The server is a user unit on the graphical session; windows are footclient.
# hosts/adeck/desk-env/alacritty.nix stays unwired so the previous terminal can be imported again.
{ pkgs, ... }:

{
  programs.foot = {
    enable = true;
    server.enable = true;

    settings = {
      main = {
        shell = "${pkgs.nushell}/bin/nu";
        font = "Syne Mono:size=14";
        pad = "5x5 center";
      };

      cursor = {
        style = "beam";
        blink = "yes";
      };

      colors-dark = {
        alpha = "0.9";
        blur = "yes";
        background = "2e3440";
        foreground = "d8dee9";
        regular0 = "3b4252";
        regular1 = "bf616a";
        regular2 = "a3be8c";
        regular3 = "ebcb8b";
        regular4 = "81a1c1";
        regular5 = "b48ead";
        regular6 = "88c0d0";
        regular7 = "e5e9f0";
        bright0 = "4c566a";
        bright1 = "bf616a";
        bright2 = "a3be8c";
        bright3 = "ebcb8b";
        bright4 = "81a1c1";
        bright5 = "b48ead";
        bright6 = "8fbcbb";
        bright7 = "eceff4";
      };
    };
  };

  # The package also ships standalone Foot and Foot Server entries. Those start a
  # second process beside foot.service. The menu entry that joins the server is footclient.
  xdg.desktopEntries = {
    foot = {
      name = "Foot";
      type = "Application";
      exec = "foot";
      noDisplay = true;
    };
    foot-server = {
      name = "Foot Server";
      type = "Application";
      exec = "foot --server";
      noDisplay = true;
    };
  };
}
