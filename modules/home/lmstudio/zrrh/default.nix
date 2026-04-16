{ config, ... }:

{
  # LM Studio config for zrrh.
  # System package (pkgs.lmstudio) handles binaries and services.
  home.activation.ensureLmstudioDirsZrrh = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.lmstudio" "$HOME/.lmstudio/models" "$HOME/.lmstudio/hub/models" "$HOME/.lmstudio/bin" "$HOME/.lmstudio/.internal"
  '';

  # Temporary: leave ~/.lmstudio/settings.json unmanaged so it can be edited imperatively on zrrh.
  home.file.".lmstudio/config-presets".source = ../config-presets;

}
