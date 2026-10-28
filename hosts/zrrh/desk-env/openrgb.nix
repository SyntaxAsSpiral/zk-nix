# OpenRGB on zrrh. Copy the repo-linked files out of /etc/nixos once.
# The GUI owns ~/.config/OpenRGB after that.
{ config, lib, ... }:

let
  unhook = import ../../../shared/home/unhook-etc-nixos.nix;
  confPath = "${config.home.homeDirectory}/.config/OpenRGB";
in
{
  home.activation.openrgbConfig = config.lib.dag.entryAfter [ "writeBoundary" ] (unhook {
    inherit lib;
    paths = [
      "${confPath}/OpenRGB.json"
      "${confPath}/boot.orp"
      "${confPath}/off.orp"
      "${confPath}/sunset.orp"
      "${confPath}/sizes.ors"
      "${confPath}/plugins/settings/EffectSettings.json"
      "${confPath}/plugins/settings/effect-profiles"
    ];
  });
}
