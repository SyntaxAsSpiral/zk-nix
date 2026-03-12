# NH maintenance policy
{ config, pkgs, ... }:

let
  perHost = {
    nxiz  = { flake = "/mnt/repository/nix-os"; };
    adeck = { flake = "/etc/nixos"; };
    zrrh  = { flake = "/etc/nixos"; };
  };
  h = perHost.${config.my.host};
in
{
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep 5 --keep-since 7d";
    };
    flake = h.flake;
  };

  environment.systemPackages = with pkgs; [
    nix-output-monitor
    nvd
  ];
}
