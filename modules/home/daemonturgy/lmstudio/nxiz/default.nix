{ config, ... }:

{
  # LM Studio config for nxiz.
  # System package (pkgs.lmstudio) handles binaries and services.
  # Mutable symlinks for LMStudio — LMStudio writes its config, so we force link to the repo.
  home.activation.lmstudioConfigNxiz = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.lmstudio" "$HOME/.lmstudio/models" "$HOME/.lmstudio/hub/models" "$HOME/.lmstudio/bin" "$HOME/.lmstudio/.internal"
    ln -sfT /mnt/repository/nix-os/modules/home/daemonturgy/lmstudio/settings.json ${config.home.homeDirectory}/.lmstudio/settings.json
    ln -sfT /mnt/repository/nix-os/modules/home/daemonturgy/lmstudio/config-presets ${config.home.homeDirectory}/.lmstudio/config-presets
    ln -sfT /mnt/repository/nix-os/modules/home/daemonturgy/lmstudio/nxiz/http-server-config.json ${config.home.homeDirectory}/.lmstudio/.internal/http-server-config.json
  '';
}
