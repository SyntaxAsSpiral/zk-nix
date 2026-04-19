{ config, ... }:

{
  # LM Studio config for nxiz.
  # System package (pkgs.lmstudio) handles binaries and services.
  home.activation.ensureLmstudioDirsNxiz = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.lmstudio" "$HOME/.lmstudio/models" "$HOME/.lmstudio/hub/models" "$HOME/.lmstudio/bin" "$HOME/.lmstudio/.internal"
  '';

  # Mutable symlinks for LMStudio
  home.activation.lmstudioConfigNxiz = config.lib.dag.entryAfter [ "linkGeneration" ] ''
    ln -sf /mnt/repository/nix-os/modules/home/daemonturgy/lmstudio/settings.json ${config.home.homeDirectory}/.lmstudio/settings.json
  '';
  home.file.".lmstudio/config-presets".source = ../config-presets;
  home.file.".lmstudio/.internal/http-server-config.json".source = ./http-server-config.json;
}
