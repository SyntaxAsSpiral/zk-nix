# User environment for adeck
{ pkgs, ... }:

{
  imports = [
    # Palette
    ../../modules/home/catppuccin.nix

    # Daemon profile (transient tooling)
    ../../modules/home/daemon-profile.nix

    # Shell
    ../../modules/home/nushell.nix

    # CLI tools
    ../../modules/home/cli/bat.nix
    ../../modules/home/cli/btop.nix
    ../../modules/home/cli/eza.nix
    ../../modules/home/cli/fzf.nix
    ../../modules/home/cli/fun.nix
    ../../modules/home/cli/gh.nix
    ../../modules/home/cli/git.nix
    ../../modules/home/cli/lazygit.nix
    ../../modules/home/cli/yazi/default.nix
    ../../modules/home/cli/fastfetch/default.nix

    # Editors
    ../../modules/home/editors/nano.nix
    ../../modules/home/editors/nixvim.nix

    # Dev
    ../../modules/home/python.nix

    # LM Studio (relay)
    ../../modules/home/daemonturgy/lmstudio/adeck/default.nix

    # Hermes Agent
    ../../modules/home/daemonturgy/hermes/default.nix

    # System
    ../../modules/home/msgvault.nix
    ../../modules/home/cli/jolt.nix
    ../../modules/home/fsel.nix
    ../../modules/home/kaleidux.nix
    ../../modules/home/niri/adeck.nix
    ../../modules/home/waybar/adeck.nix
    ../../modules/home/terminal/alacritty.nix
    ../../modules/home/xdg.nix
  ];

  home.username = "zk";
  home.homeDirectory = "/home/zk";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  programs.msgvault.enable = true;

  home.packages = with pkgs; [
    nerd-fonts.recursive-mono
    git-lfs
    nodejs_24
    lazydocker
    htop
    (import ../../modules/home/cli/zcli.nix {
      inherit pkgs;
      flakePath = "/etc/nixos";
    })

  ];

  home.file = {
    ".face".source = ../../assets/adeck-face.png;
  };
}
