# One otter-launcher for every host. The modules use only shell kit tools.
{ pkgs, inputs, ... }:
{
  home.packages = [
    inputs.otter-launcher.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  xdg.configFile."otter-launcher/config.toml".source = ./otter-launcher/config.toml;
  xdg.configFile."otter-launcher/nixos.png".source = ../../assets/nixos.png;
}
