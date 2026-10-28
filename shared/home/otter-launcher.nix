# One otter-launcher for every host. The modules use only shell kit tools.
{ pkgs, inputs, ... }:
let
  # The front door: the NixOS logo beside the host, the time, the mesh, and a chronohex.
  otterHeader = pkgs.writeShellApplication {
    name = "otter-header";
    runtimeInputs = with pkgs; [
      chafa
      coreutils
      gnugrep
      gnused
      tailscale
    ];
    text = ''
      LOGO=${../../assets/nixos.png}
      ALCHEMY=${./otter-launcher/alchemy.txt}
      ${builtins.readFile ./otter-launcher/header.sh}
    '';
  };
in
{
  home.packages = [
    inputs.otter-launcher.packages.${pkgs.stdenv.hostPlatform.system}.default
    otterHeader
  ];

  xdg.configFile."otter-launcher/config.toml".source = ./otter-launcher/config.toml;
}
