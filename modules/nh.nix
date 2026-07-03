# NH maintenance policy
{ config, pkgs, ... }:

{
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep 5 --keep-since 7d";
    };
    flake = config.my.flakePath;
  };

  environment.systemPackages = with pkgs; [
    nix-output-monitor
    nvd
  ];
}
