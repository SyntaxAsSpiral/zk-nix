{ config, ... }:

{
  # LM Studio config for adeck.
  # The CLI/daemon binaries are installed natively into ~/.lmstudio/bin by:
  #   curl -fsSL https://lmstudio.ai/install.sh | bash
  # Keep this module to seed config only; do not install or service-wrap llmster.
  home.activation.lmstudioConfigAdeck = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.lmstudio" "$HOME/.lmstudio/models" "$HOME/.lmstudio/hub/models" "$HOME/.lmstudio/bin" "$HOME/.lmstudio/.internal"
    ln -sfT /etc/nixos/modules/home/daemonturgy/lmstudio/adeck/settings.json ${config.home.homeDirectory}/.lmstudio/settings.json
    ln -sfT /etc/nixos/modules/home/daemonturgy/lmstudio/config-presets ${config.home.homeDirectory}/.lmstudio/config-presets
    ln -sfT /etc/nixos/modules/home/daemonturgy/lmstudio/adeck/http-server-config.json ${config.home.homeDirectory}/.lmstudio/.internal/http-server-config.json
  '';
}
