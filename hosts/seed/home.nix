# Seed home: nushell and the shared CLI set. Console only. No Zed.
{ pkgs, ... }:
{
  imports = [
    ../../shared/home/nushell.nix
    ../../shared/home/fastfetch/default.nix
    ../../shared/home/gh.nix
    ../../shared/home/otter-launcher.nix
    ../../shared/home/yazi/default.nix
    ../../shared/home/zcli.nix
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
