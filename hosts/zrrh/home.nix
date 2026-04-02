# User environment for zrrh — inference/media/gaming workstation
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    # Palette
    ../../modules/home/catppuccin.nix

    # Shell
    ../../modules/home/nushell.nix
    ../../modules/home/cli/fish/default.nix
    ../../modules/home/lmstudio/zrrh/default.nix

    # CLI tools
    ../../modules/home/cli/bat.nix
    ../../modules/home/cli/btop.nix
    ../../modules/home/cli/eza.nix
    ../../modules/home/cli/fastfetch/default.nix
    ../../modules/home/cli/fun.nix
    ../../modules/home/cli/fzf.nix
    ../../modules/home/cli/gh.nix
    ../../modules/home/cli/git.nix
    ../../modules/home/cli/lazygit.nix
    ../../modules/home/cli/yazi/default.nix

    # Editors
    ../../modules/home/editors/nano.nix
    ../../modules/home/editors/nixvim.nix

    # Browser
    ../../modules/home/browser/firefox.nix

    # Launcher
    ../../modules/home/otter-launcher/zrrh/default.nix

    # Theming
    ../../modules/home/gtk.nix
    ../../modules/home/icons.nix

    # System
    ../../modules/home/spotify.nix
    ../../modules/home/niri/zrrh.nix
    ../../modules/home/terminal/ghostty.nix

    ../../modules/home/noctalia/zrrh/default.nix
    ../../modules/openrgb/home.nix
    ../../modules/home/thunar.nix
    ../../modules/home/xdg.nix
  ];


  home.username = "zk";
  home.homeDirectory = "/home/zk";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableFishIntegration = true;
  };

  programs.fish.shellAliases = {
    deck-torrents-sync = "ssh zk@adeck '/etc/nixos/scripts/qbt-sync-zrrh.sh'";
  };

  # Allow nwg-look/GTK to be managed dynamically by disabling declarative HM GTK
  gtk.enable = lib.mkForce false;



  home.packages = with pkgs; [
    # zcli — zrrh builds locally, flake path is local
    (import ../../modules/home/cli/zcli.nix {
      inherit pkgs;
      flakePath = "/etc/nixos";
    })

    # pi wrapper (same behavior as nxiz)
    (writeShellApplication {
      name = "pi";
      runtimeInputs = [ nodejs ];
      text = ''
        set -euo pipefail
        exec npx --yes @mariozechner/pi-coding-agent "$@"
      '';
    })

    # Media key controls for Niri binds
    playerctl

    # Emoji picker (fzf + otter module, no rofi)
    (writeShellApplication {
      name = "fzf-emoji";
      runtimeInputs = [ fzf jq wl-clipboard curl coreutils ];
      text = ''
        set -euo pipefail

        data_url="https://raw.githubusercontent.com/github/gemoji/0eca75db9301421efc8710baf7a7576793ae452a/db/emoji.json"
        cache_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/fzf-emoji"
        data_file="$cache_dir/emoji.json"

        mkdir -p "$cache_dir"
        if [ ! -s "$data_file" ]; then
          curl -fsSL "$data_url" -o "$data_file"
        fi

        jq -r '.[] | (.emoji + " :" + .aliases[0] + ": " + .category + " » " + .description)' "$data_file" |
          fzf \
            --delimiter ' ' \
            --layout=reverse \
            --prompt 'emoji> ' \
            --bind 'enter:become(printf {1} | wl-copy --trim-newline)' \
            --bind 'ctrl-y:become(printf {2} | wl-copy --trim-newline)'
      '';
    })

    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  programs.ghostty.settings = {
    custom-shader = "${config.xdg.configHome}/ghostty/cursor-blaze.glsl";
  };

  home.file = {
    ".face".source = ../../assets/zrrh-face.png;
    ".config/ghostty/cursor-blaze.glsl".source = ../../modules/home/terminal/cursor-blaze.glsl;
  };
}
