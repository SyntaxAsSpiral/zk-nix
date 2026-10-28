# Seed home: nushell and the shared CLI set. XFCE is system-level. No Zed.
{ pkgs, ... }:
{
  imports = [
    ../../shared/home/nushell.nix
    ../../shared/home/shell/fastfetch/default.nix
    ../../shared/home/shell/gh.nix
    ../../shared/home/shell/lazygit.nix
    ../../shared/home/shell/zcli.nix
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
