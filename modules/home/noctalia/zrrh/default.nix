{ config, ... }:

{
  # Mutable symlinks — noctalia GUI writes config back to repo
  # Must run after linkGeneration which otherwise restores the nix store symlink
  home.activation.noctaliaConfig = config.lib.dag.entryAfter [ "linkGeneration" ] ''
    ln -sf /etc/nixos/modules/home/noctalia/zrrh/settings.json ${config.home.homeDirectory}/.config/noctalia/settings.json
    ln -sf /etc/nixos/modules/home/noctalia/zrrh/plugins.json ${config.home.homeDirectory}/.config/noctalia/plugins.json
    ln -sf /etc/nixos/modules/home/noctalia/zrrh/colors.json ${config.home.homeDirectory}/.config/noctalia/colors.json
  '';
}
