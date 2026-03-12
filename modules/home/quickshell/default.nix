{ pkgs, ... }: {
  # Quickshell runtime
  home.packages = [ pkgs.quickshell ];

  # Configuration files
  xdg.configFile."quickshell/shell.qml".source = ./shell.qml;
  xdg.configFile."quickshell/utils".source = ./utils;
}
