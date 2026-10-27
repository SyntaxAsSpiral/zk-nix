# Seed home: nushell and the shared CLI set. XFCE is system-level. No Zed.
{ pkgs, ... }:
{
  imports = [
    ../../modules/home/nushell.nix
    ../../modules/home/shell/bat.nix
    ../../modules/home/shell/btop.nix
    ../../modules/home/shell/eza.nix
    ../../modules/home/shell/fastfetch/default.nix
    ../../modules/home/shell/fun.nix
    ../../modules/home/shell/fzf.nix
    ../../modules/home/shell/gh.nix
    ../../modules/home/shell/git.nix
    ../../modules/home/shell/lazygit.nix
    ../../modules/home/shell/yazi/default.nix
    ../../modules/home/shell/zcli.nix
    ../../modules/home/daemonturgy/pi/default.nix
  ];

  home = {
    username = "zk";
    homeDirectory = "/home/zk";
    stateVersion = "25.11";

    packages = with pkgs; [
      fastfetch
      nodejs
    ];
  };

  programs.home-manager.enable = true;
}
