{ config, pkgs, ... }:
{
  home.packages = [ pkgs.mods ];

  home.activation.modsConfig = config.lib.dag.entryAfter [ "linkGeneration" ] ''
    ln -sf /mnt/repository/nix-os/modules/home/mods/mods.yml ~/.config/mods/mods.yml
  '';
}
