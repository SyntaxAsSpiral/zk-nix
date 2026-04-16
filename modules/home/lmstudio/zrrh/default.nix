{ config, ... }:

{
  # LM Studio config for zrrh.
  # System package (pkgs.lmstudio) handles binaries and services.
  home.activation.ensureLmstudioDirsZrrh = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.lmstudio" "$HOME/.lmstudio/models" "$HOME/.lmstudio/hub/models" "$HOME/.lmstudio/bin" "$HOME/.lmstudio/.internal"
  '';

  home.file.".lmstudio/settings.json".source = ./settings.json;
  home.file.".lmstudio/config-presets".source = ../config-presets;

  # Noctalia launches apps through XDG desktop entries.
  # Provide a local override with an absolute Exec to avoid launcher lookup failures.
  home.file.".local/share/applications/lm-studio.desktop".text = ''
    [Desktop Entry]
    Name=LM Studio
    Exec=/etc/profiles/per-user/zk/bin/lm-studio
    Terminal=false
    Type=Application
    Icon=lm-studio
    StartupWMClass=LM-Studio
    Comment=Use the chat UI or local server to experiment and develop with local LLMs.
    Keywords=developer;llm;
    Categories=Development;Utility;
    MimeType=x-scheme-handler/lmstudio;
  '';
}
