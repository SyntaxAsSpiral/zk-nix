{ config, ... }:

{
  # Symlink the Niri config directly to the repo file so changes are instant without rebuilds
  home.activation.niriConfig = config.lib.dag.entryAfter [ "linkGeneration" ] ''
    ln -sf /etc/nixos/modules/home/niri/config-zrrh.kdl ${config.home.homeDirectory}/.config/niri/config.kdl
  '';
}
