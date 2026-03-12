{ pkgs, ... }:
let
  kiroFHS = pkgs.buildFHSEnv {
    name = "kiro";
    targetPkgs = pkgs: with pkgs; [
      glib
      gtk3
      nss
      nspr
      dbus
      atk
      at-spi2-atk
      at-spi2-core
      cups
      cairo
      pango
      libdrm
      expat
      libxkbcommon
      libx11
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
      libxcb
      mesa
      libgbm
      alsa-lib
      systemd  # libudev
    ];
    runScript = pkgs.writeShellScript "kiro-launch" ''
      exec ~/.local/lib/kiro/kiro --no-sandbox "$@"
    '';
  };
in
{
  home.packages = [ kiroFHS ];

  xdg.configFile."kiro/User/settings.json".source = ./vscode/User/settings.json;

  xdg.desktopEntries.kiro = {
    name = "Kiro";
    genericName = "IDE";
    exec = "kiro %F";
    icon = "kiro";
    terminal = false;
    type = "Application";
    categories = [ "Development" "IDE" ];
  };
}
