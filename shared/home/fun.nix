# Fun terminal toys: the shell kit's, on every host through the otter imports. cava is its own module.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    lolcat
    toilet
    figlet
    cowsay
    fortune
    neo
  ];

  xdg.configFile = {
    # neo themes on ANSI palette codes, so the terminal theme sets every colour. Run with
    # --colormode=16: neo -C ~/.config/neo/ansi-matrix.cfg --colormode=16. A -1 is the default background.
    "neo/ansi-matrix.cfg".text = ''
      neo_color_version 1
      # bg: the terminal's own
      -1
      # dim trail: bright black
      8
      # body: green
      2
      # head: bright green
      10
      # bright tip: bright white
      15
    '';

    "neo/ansi-rainbow.cfg".text = ''
      neo_color_version 1
      -1
      # dim trail: bright black
      8
      # red, yellow, green, cyan, blue, magenta: the six hues in palette order
      1
      3
      2
      6
      4
      5
      # bright tip: bright white
      15
    '';

    # neo screensaver color file — Frappe bg, Mocha Sapphire gradient
    "neo/frappe-sapphire.cfg".text = ''
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
    "neo/mocha-rainbow.cfg".text = ''
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
    "neo/daemon-forge.cfg".text = ''
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
  };
}
