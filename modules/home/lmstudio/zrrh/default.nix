{ config, ... }:

{
  # LM Studio config for zrrh.
  # System package (pkgs.lmstudio) handles binaries and services.
  home.activation.ensureLmstudioDirsZrrh = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.lmstudio" "$HOME/.lmstudio/models" "$HOME/.lmstudio/hub/models" "$HOME/.lmstudio/bin" "$HOME/.lmstudio/.internal"
  '';

  # Temporary: leave ~/.lmstudio/settings.json unmanaged so it can be edited imperatively on zrrh.
  home.file.".lmstudio/config-presets".source = ../config-presets;

  # Manual launcher entry for Noctalia on zrrh.
  # Keep a unique desktop ID so it does not collide with the package-provided lm-studio.desktop.
  home.file.".local/share/applications/lm-studio-manual.desktop".text = ''
    [Desktop Entry]
    Version=1.0
    Type=Application
    Name=LM Studio Manual
    Comment=Launch LM Studio via absolute path
    Exec=/etc/profiles/per-user/zk/bin/lm-studio
    TryExec=/etc/profiles/per-user/zk/bin/lm-studio
    Icon=lm-studio
    Terminal=false
    Categories=Development;Utility;
    StartupWMClass=LM-Studio
  '';

}
