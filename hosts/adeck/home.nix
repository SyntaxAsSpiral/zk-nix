# User environment for adeck
{ pkgs, ... }:

{
  imports = [
    ../../modules/home/profiles/base.nix

    # adeck-specific
    # bb-server (Bitburner WS sync + MCP); off while not playing
    # ../../modules/home/bb-server.nix

    # Dev
    ../../modules/home/python.nix

    # LM Studio (relay)
    ../../modules/home/daemonturgy/lmstudio/adeck/default.nix

    # Festin kitchen (adeck only)
    ../../modules/home/festin.nix

    # Esotericons fetch (same module as nxiz)
    ../../modules/home/shell/fastfetch/eso-fetch.nix

    # System
    ../../modules/home/msgvault.nix
    ../../modules/home/shell/jolt.nix
    ../../modules/home/fsel.nix
    ../../modules/home/otter-launcher/adeck
    ../../modules/home/awww-cycle.nix
    ../../modules/home/niri/adeck.nix
    ../../modules/home/waybar/adeck.nix
    ../../modules/home/terminal/alacritty.nix
  ];

  home = {
    stateVersion = "24.11";

    packages = with pkgs; [
      nerd-fonts.recursive-mono
      git-lfs
      nodejs_24
      lazydocker
      htop
      firefox
    ];

    file.".face".source = ../../assets/adeck-face.png;
  };

  programs.msgvault.enable = true;
}
