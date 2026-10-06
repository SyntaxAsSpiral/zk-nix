# Seed home: nushell and the shared CLI set. No desktop, no Zed, no fonts.
{ pkgs, ... }:
{
  imports = [
    ../../modules/home/nushell.nix
    ../../modules/home/cli/bat.nix
    ../../modules/home/cli/btop.nix
    ../../modules/home/cli/eza.nix
    ../../modules/home/cli/fastfetch/default.nix
    ../../modules/home/cli/fun.nix
    ../../modules/home/cli/fzf.nix
    ../../modules/home/cli/gh.nix
    ../../modules/home/cli/git.nix
    ../../modules/home/cli/lazygit.nix
    ../../modules/home/cli/yazi/default.nix
    ../../modules/home/cli/zcli.nix
  ];

  home.username = "zk";
  home.homeDirectory = "/home/zk";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    fastfetch
    nodejs
  ];
}
