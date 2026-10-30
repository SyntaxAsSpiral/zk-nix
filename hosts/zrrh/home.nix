# User environment for zrrh — inference/media/gaming workstation
{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ../../shared/home/daemon-profile.nix
    ../../shared/home/nushell.nix
    ../../shared/home/xdg.nix
    ../../shared/home/fastfetch/default.nix
    ../../shared/home/fun.nix
    ../../shared/home/gh.nix
    ../../shared/home/otter-launcher.nix
    ../../shared/home/zcli.nix
    ../../shared/home/editors/nano.nix
    ../../shared/home/yazi/default.nix
    ../../shared/home/editors/zed.nix
    ../../shared/home/pi/default.nix

    ../../shared/home/browser/firefox.nix
    ../../shared/home/gtk.nix
    ../../shared/home/icons.nix
    ../../shared/home/spotify.nix
    ../../shared/home/thunar.nix
    ../../shared/home/fzf-emoji.nix

    ./desk-env/lmstudio-autorun.nix
    ../../shared/home/niri.nix
    ./desk-env/ghostty.nix
  ];

  programs.home-manager.enable = true;

  home = {
    username = "zk";
    homeDirectory = "/home/zk";
    stateVersion = "25.11";

    packages = with pkgs; [
      # Media key controls for Niri binds
      playerctl
      zathura
      lmstudio

      noctalia-shell
    ];

    file = {
      ".face".source = ../../assets/zrrh-face.png;
      ".config/ghostty/cursor-blaze.glsl".source = ./desk-env/cursor-blaze.glsl;
    };
  };

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableNushellIntegration = true;
    };

    ghostty.settings = {
      custom-shader = "${config.xdg.configHome}/ghostty/cursor-blaze.glsl";
    };
  };
}
