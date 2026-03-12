# Fun terminal toys
{ pkgs, lib, osConfig ? {}, ... }:

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
  home.packages = with pkgs; [
    lolcat
    toilet
    figlet
    cowsay
    fortune
    neo
  ];

  # neo screensaver color file — Frappe bg, Mocha Sapphire gradient
  xdg.configFile."neo/frappe-sapphire.cfg".text = ''
    neo_color_version 1
    # bg: Frappe Base #303446
    236, 188, 204, 275
    # dim trail: Frappe Surface0 #414559
    238, 255, 271, 349
    # dim sapphire
    67,  180, 400, 520
    # Frappe Sapphire #85c1dc
    74,  522, 757, 863
    # Mocha Sapphire #74c7ec
    117, 455, 780, 925
    # bright tip: Mocha Text #cdd6f4
    195, 804, 839, 957
  '';

  # neo screensaver — all mocha accent colors
  xdg.configFile."neo/mocha-rainbow.cfg".text = ''
    neo_color_version 1
    # bg: Frappe Base #303446
    236, 188, 204, 275
    # dim trail: Frappe Surface0 #414559
    238, 255, 271, 349
    # dim trail: Frappe Overlay0 #737994
    243, 451, 475, 580
    # Red #f38ba8
    210, 953, 545, 659
    # Maroon #eba0ac
    210, 922, 627, 675
    # Peach #fab387
    216, 980, 702, 529
    # Flamingo #f2cdcd
    218, 949, 804, 804
    # Yellow #f9e2af
    223, 976, 886, 686
    # Rosewater #f5e0dc
    224, 961, 878, 863
    # Green #a6e3a1
    114, 651, 890, 631
    # Teal #94e2d5
    115, 580, 886, 835
    # Sky #89dceb
    116, 537, 863, 922
    # Sapphire #74c7ec
    117, 455, 780, 925
    # Lavender #b4befe
    147, 706, 745, 996
    # Blue #89b4fa
    111, 537, 706, 980
    # Mauve #cba6f7
    141, 796, 651, 969
    # Pink #f5c2e7
    218, 961, 761, 906
    # bright tip: Mocha Text #cdd6f4
    195, 804, 839, 957
  '';

  # neo screensaver — daemon forge (zrrh motif: ember, amber, peach, raspberry, lilac, rosewater)
  xdg.configFile."neo/daemon-forge.cfg".text = ''
    neo_color_version 1
    # bg: deep ember (dark warm near-black)
    52,  188, 204, 275
    # smolder: dim amber glow
    94,  255, 271, 349
    # amber: warm mid-trail (dim Peach)
    216, 700, 450, 580
    # Peach #fab387
    216, 980, 702, 529
    # sunset blood: Mocha Red #f38ba8
    210, 953, 545, 659
    # Maroon/Raspberry #eba0ac
    210, 922, 627, 675
    # Pink #f5c2e7
    218, 961, 761, 906
    # Mauve/Lilac #cba6f7
    141, 796, 651, 969
    # bright tip: Rosewater #f5e0dc
    224, 961, 878, 863
  '';

  # Audio visualizer
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
