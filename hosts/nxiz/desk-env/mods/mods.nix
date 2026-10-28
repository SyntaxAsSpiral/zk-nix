{ config, lib, pkgs, ... }:
let
  unhook = import ../../../../shared/home/unhook-etc-nixos.nix;
in
{
  home.packages = [ pkgs.mods ];

  # Copy mods.yml out of /etc/nixos once. mods owns it after that.
  home.activation.modsConfig = config.lib.dag.entryAfter [ "writeBoundary" ] (unhook {
    inherit lib;
    paths = [ "${config.home.homeDirectory}/.config/mods/mods.yml" ];
  });
}
