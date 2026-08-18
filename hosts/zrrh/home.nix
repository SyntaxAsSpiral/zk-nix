# User environment for zrrh — inference/media/gaming workstation
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    ../../modules/home/profiles/base.nix
    ../../modules/home/profiles/desktop.nix

    # zrrh-specific
    ../../modules/home/cli/fish/default.nix
    ../../modules/home/daemonturgy/lmstudio/zrrh/default.nix
    ../../modules/home/otter-launcher/zrrh/default.nix
    ../../modules/home/niri/zrrh.nix
    ../../modules/home/terminal/ghostty.nix
    ../../modules/home/noctalia/zrrh/default.nix
    ../../modules/home/openrgb.nix
  ];

  home = {
    stateVersion = "25.11";

    packages = with pkgs; [
      # Media key controls for Niri binds
      playerctl
      zathura
      lmstudio

      inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    file = {
      ".face".source = ../../assets/zrrh-face.png;
      ".config/ghostty/cursor-blaze.glsl".source = ../../modules/home/terminal/cursor-blaze.glsl;
    };
  };

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableFishIntegration = true;
    };

    fish.shellAliases = {
      deck-torrents-sync = "ssh zk@adeck '/etc/nixos/scripts/qbt-sync-zrrh.sh'";
    };

    ghostty.settings = {
      custom-shader = "${config.xdg.configHome}/ghostty/cursor-blaze.glsl";
    };
  };

  # Allow nwg-look/GTK to be managed dynamically by disabling declarative HM GTK
  gtk.enable = lib.mkForce false;
}
