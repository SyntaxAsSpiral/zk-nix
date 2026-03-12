{ pkgs, inputs, ... }:

{
  home.packages = [
    inputs.otter-launcher.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.libqalculate # for qalc
  ];

  xdg.configFile."otter-launcher/config.toml".source = ./config.toml;
  xdg.configFile."otter-launcher/nixos.png".source = ../../../assets/nixos.png;
}
