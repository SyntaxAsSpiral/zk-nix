# Audio visualizer, for the hosts with a speaker. Colours follow the host's gradient direction.
{ lib, osConfig ? {}, ... }:

let
  host = lib.attrByPath [ "my" "host" ] "" osConfig;
  cavaColors =
    if host == "zrrh" then {
      # zrrh: reverse the default gradient direction
      gradient = 1;
      gradient_color_1 = "'#ed8796'";
      gradient_color_2 = "'#ee99a0'";
      gradient_color_3 = "'#f5bde6'";
      gradient_color_4 = "'#c6a0f6'";
      gradient_color_5 = "'#8aadf4'";
      gradient_color_6 = "'#7dc4e4'";
      gradient_color_7 = "'#91d7e3'";
      gradient_color_8 = "'#8bd5ca'";
    } else {
      gradient = 1;
      gradient_color_1 = "'#8bd5ca'";
      gradient_color_2 = "'#91d7e3'";
      gradient_color_3 = "'#7dc4e4'";
      gradient_color_4 = "'#8aadf4'";
      gradient_color_5 = "'#c6a0f6'";
      gradient_color_6 = "'#f5bde6'";
      gradient_color_7 = "'#ee99a0'";
      gradient_color_8 = "'#ed8796'";
    };
in
{
  programs.cava = {
    enable = true;
    settings = {
      general = {
        bar_spacing = 1;
        bar_width = 2;
        frame_rate = 60;
      };
      color = cavaColors;
    };
  };
}
