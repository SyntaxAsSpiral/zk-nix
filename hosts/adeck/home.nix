# User environment for adeck
{ pkgs, ... }:

{
  imports = [
    ../../modules/home/profiles/base.nix

    # adeck-specific
    # bb-server (Bitburner WS sync + MCP)
    ../../modules/home/bb-server.nix

    # Dev
    ../../modules/home/python.nix

    # LM Studio (relay)
    ../../modules/home/daemonturgy/lmstudio/adeck/default.nix

    # Hermes Agent (adeck only)
    ../../modules/home/daemonturgy/hermes/default.nix

    # Esocortex read-only API (adeck only)
    ../../modules/home/daemonturgy/esocortex/default.nix

    # Herm TUI
    ../../modules/home/daemonturgy/herm/default.nix

    # Stack-chan bridge
    ../../modules/home/daemonturgy/stackchan/default.nix

    # Esotericons fetch (same module as nxiz)
    ../../modules/home/cli/fastfetch/eso-fetch.nix

    # System
    ../../modules/home/msgvault.nix
    ../../modules/home/cli/jolt.nix
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
