# User environment for adeck
{ pkgs, ... }:

let
  nullclaw = pkgs.runCommand "nullclaw-2026.3.1" {
    src = pkgs.fetchurl {
      url = "https://github.com/nullclaw/nullclaw/releases/download/v2026.3.1/nullclaw-linux-x86_64.bin";
      hash = "sha256-RLxfKf99T0TXRvusOeZV1bdyK+sKkgQyWB7/315SOok=";
    };
    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
  } ''
    install -Dm755 $src $out/bin/nullclaw
  '';

  zeroclaw = pkgs.stdenv.mkDerivation {
    pname = "zeroclaw";
    version = "0.1.7";
    src = pkgs.fetchurl {
      url = "https://github.com/zeroclaw-labs/zeroclaw/releases/download/v0.1.7/zeroclaw-x86_64-unknown-linux-gnu.tar.gz";
      hash = "sha256-tbJvBq9Zc7cgZlYZCpTfO9KkIr8tQv1tXaJaQvL29tA=";
    };
    sourceRoot = ".";
    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = [ pkgs.openssl pkgs.stdenv.cc.cc.lib ];
    installPhase = ''
      install -Dm755 zeroclaw $out/bin/zeroclaw
    '';
  };

  picoclaw = pkgs.buildGoModule {
    pname = "picoclaw";
    version = "unstable-2026-03-02";
    src = pkgs.fetchFromGitHub {
      owner = "sipeed";
      repo = "picoclaw";
      rev = "0150947e61f167507d0d1271cbcef70b74402342";
      hash = "sha256-UNNdNDojYoGdUna5axvM8QEygrfaUcAfvk+5dMQcCHo=";
    };
    vendorHash = "sha256-/+O6KAOqINwhm3bZ4ncFtm48KJPwYFmb2K/8OBLssFQ=";
    preBuild = ''
      cp -r workspace cmd/picoclaw/internal/onboard/
    '';
    doCheck = false;
    meta.mainProgram = "picoclaw";
  };
in
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

    # *claw agent runtimes
    nullclaw
    zeroclaw
    picoclaw
  ];

  home.file = {
    ".face".source = ../../assets/adeck-face.png;
  };
}
