{ config, pkgs, ... }:
{
  home.packages = [
    pkgs.hyprpanel
    ## Used for Tracking GPU Usage in your Dashboard (NVidia only)
    # python
    # python-gpustat

    ## To control screen/keyboard brightness
    # brightnessctl

    ## Only if a pywal hook from wallpaper changes applied through settings is desired
    # pywal

    ## To check for pacman updates in the default script used in the updates module
    # pacman-contrib

    ## To switch between power profiles in the battery module
    # power-profiles-daemon

    ## To take snapshots with the default snapshot shortcut in the dashboard
    # grimblast

    ## To record screen through the dashboard record shortcut
    pkgs.wf-recorder

    ## To enable the eyedropper color picker with the default snapshot shortcut in the dashboard
    # hyprpicker

    ## To enable hyprland's very own blue light filter
    # hyprsunset

    ## To click resource/stat bars in the dashboard and open btop
    # btop

    ## To enable matugen based color theming
    pkgs.matugen

    ## To enable matugen based color theming and setting wallpapers via hyprpanel
    pkgs.awww
  ];

  # Mutable symlinks — hyprpanel GUI writes config back to repo
  # Must run after linkGeneration which otherwise restores the nix store symlink
  home.activation.hyprpanelConfig = config.lib.dag.entryAfter [ "linkGeneration" ] ''
    ln -sf /mnt/repository/nix-os/modules/home/hyprpanel/config.json ~/.config/hyprpanel/config.json
    ln -sf /mnt/repository/nix-os/modules/home/hyprpanel/modules.json ~/.config/hyprpanel/modules.json
    ln -sf /mnt/repository/nix-os/modules/home/hyprpanel/modules.scss ~/.config/hyprpanel/modules.scss
  '';
}
