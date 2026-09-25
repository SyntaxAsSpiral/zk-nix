{ config, pkgs, ... }: {
  home.packages = [ pkgs.mods ];

  home.activation.modsConfig = config.lib.dag.entryAfter [ "linkGeneration" ] ''
    ln -sf /etc/nixos/modules/home/daemonturgy/mods/mods.yml ~/.config/mods/mods.yml
  '';
}
