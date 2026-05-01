{ pkgs, osConfig, ... }:

let
  # JetBrains Mono is highly legible on small, dense screens
  font = "Syne Mono";
  # Bumping up the font size significantly for the Steam Deck
  fontSize = if osConfig.my.host == "adeck" then 14 else 12;
in
{
  home.packages = [ pkgs.alacritty ];

  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding = {
          x = 5;
          y = 5;
        };
        dynamic_padding = true;
        opacity = 0.9;
        blur = true;
      };

      font = {
        normal = {
          family = font;
          style = "Regular";
        };
        bold = {
          family = font;
          style = "Bold";
        };
        italic = {
          family = font;
          style = "Italic";
        };
        size = fontSize;
      };

      cursor = {
        style = {
          shape = "Beam";
          blinking = "On";
        };
      };

      terminal.shell = {
        program = "${pkgs.nushell}/bin/nu";
      };
    }
    // (
      if osConfig.my.host == "adeck" then
        {
          colors = {
            primary = {
              background = "#2E3440";
              foreground = "#D8DEE9";
            };
            normal = {
              black = "#3B4252";
              red = "#BF616A";
              green = "#A3BE8C";
              yellow = "#EBCB8B";
              blue = "#81A1C1";
              magenta = "#B48EAD";
              cyan = "#88C0D0";
              white = "#E5E9F0";
            };
            bright = {
              black = "#4C566A";
              red = "#BF616A";
              green = "#A3BE8C";
              yellow = "#EBCB8B";
              blue = "#81A1C1";
              magenta = "#B48EAD";
              cyan = "#8FBCBB";
              white = "#ECEFF4";
            };
          };
        }
      else
        { }
    );
  };
}
