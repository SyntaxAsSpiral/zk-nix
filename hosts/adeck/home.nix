# User environment for adeck
{ pkgs, ... }:

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

    ../../shared/home/python.nix
    ../../shared/home/msgvault.nix
    ../../shared/home/fsel.nix

    ./desk-env/lmstudio/default.nix
    ./desk-env/festin.nix
    ./desk-env/jolt.nix
    ./desk-env/awww-cycle.nix
    ../../shared/home/niri.nix
    ./desk-env/waybar.nix
    ./desk-env/alacritty.nix
  ];

  programs.home-manager.enable = true;

  home = {
    username = "zk";
    homeDirectory = "/home/zk";
    stateVersion = "24.11";

    packages = with pkgs; [
      nerd-fonts.recursive-mono
      git-lfs
      nodejs_24
      lazydocker
      htop
      firefox
    ];

    file.".face".source = ../../assets/adeck-face.png;
  };

  programs.msgvault.enable = true;
}
