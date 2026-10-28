{ config, lib, ... }:

let
  unhook = import ../../../shared/home/unhook-etc-nixos.nix;
in
{
  # Copy the niri config out of /etc/nixos once. Niri owns it after that.
  home.activation.niriConfig = config.lib.dag.entryAfter [ "writeBoundary" ] (unhook {
    inherit lib;
    paths = [ "${config.home.homeDirectory}/.config/niri/config.kdl" ];
  });
}
