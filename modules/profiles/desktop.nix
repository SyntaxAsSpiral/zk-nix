# Desktop workstation profile — nxiz + zrrh (NVIDIA GUI hosts).
# adeck deliberately does not import this.
{ pkgs, ... }:

{
  imports = [
    ../nvidia.nix
    ../steam.nix
    ../performance.nix
  ];

  my.performance.enable = true;

  # Thunar service + plugins
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-volman
      thunar-archive-plugin
    ];
  };

  programs.appimage = {
    enable = true;
    binfmt = true;
  };
}
