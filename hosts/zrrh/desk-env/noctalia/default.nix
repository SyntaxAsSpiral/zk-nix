{ config, lib, ... }:

let
  unhook = import ../../../../shared/home/unhook-etc-nixos.nix;
  noctalia = "${config.home.homeDirectory}/.config/noctalia";
in
{
  # Copy Noctalia's files out of /etc/nixos once. The shell owns them after that.
  home.activation.noctaliaConfig = config.lib.dag.entryAfter [ "writeBoundary" ] (unhook {
    inherit lib;
    paths = [
      "${noctalia}/settings.json"
      "${noctalia}/plugins.json"
      "${noctalia}/colors.json"
    ];
  });
}
