{ config, pkgs, ... }:

{
  # LM Studio on nxiz: GUI (AppImage) + lms curl installer.
  # Will migrate to nixpkg when LM Studio 4.6 lands.
  home.activation.ensureLmstudioDirsNxiz = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.lmstudio" "$HOME/.lmstudio/models" "$HOME/.lmstudio/hub/models" "$HOME/.lmstudio/bin" "$HOME/.lmstudio/.internal"
  '';

  home.file.".lmstudio/settings.json".source = ./settings.json;
  home.file.".lmstudio/config-presets".source = ../config-presets;
  home.file.".lmstudio/.internal/http-server-config.json".source = ./http-server-config.json;

  xdg.desktopEntries.lm-studio = {
    name = "LM Studio";
    comment = "Local LLM development and inference";
    exec = "env ELECTRON_OZONE_PLATFORM_HINT=auto /home/zk/.lmstudio/bin/LM-Studio.AppImage --no-sandbox --enable-features=UseOzonePlatform,WaylandWindowDecorations %U";
    terminal = false;
    type = "Application";
    categories = [ "Development" "Utility" ];
    mimeType = [ "x-scheme-handler/lmstudio" ];
    settings = {
      Keywords = "developer;llm;";
      StartupWMClass = "LM Studio";
    };
  };
}
