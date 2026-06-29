# User environment: identity, apps, system utils
{
  config,
  pkgs,
  inputs,
  ...
}:

let
  pinnedSonicPiPkgs = inputs.nixpkgs-sonic-pi.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  sonicPiPinned = (
    (pinnedSonicPiPkgs.sonic-pi.override {
      ruby = pinnedSonicPiPkgs.ruby_3_3;
      boost = pinnedSonicPiPkgs.boost186;
    }).overrideAttrs
      (old: {
        doCheck = false;
        meta = old.meta // {
          broken = false;
        };
      })
  );
in

{
  imports = [
    ../../modules/home/catppuccin.nix
    ../../modules/home/daemon-profile.nix
    ../../modules/home/cli/bat.nix
    ../../modules/home/cli/btop.nix
    ../../modules/home/cli/eza.nix
    ../../modules/home/cli/fastfetch/default.nix
    ../../modules/home/cli/fastfetch/eso-fetch.nix
    ../../modules/home/cli/fun.nix
    ../../modules/home/cli/fzf.nix
    ../../modules/home/cli/gh.nix
    ../../modules/home/cli/git.nix
    ../../modules/home/cli/lazygit.nix
    ../../modules/home/cli/yazi/default.nix
    ../../modules/home/editors/nano.nix
    ../../modules/home/editors/obsidian.nix
    ../../modules/home/editors/zed.nix
    ../../modules/home/browser/firefox.nix
    ../../modules/home/fsel.nix
    ../../modules/home/otter-launcher/otter-launcher.nix
    ../../modules/home/gtk.nix
    ../../modules/home/hyprland/hyprland.nix
    ../../modules/home/awww.nix
    ../../modules/home/icons.nix
    ../../modules/home/daemonturgy/mods/mods.nix
    ../../modules/home/nushell.nix
    ../../modules/home/daemonturgy/lmstudio/nxiz/default.nix
    ../../modules/home/spotify.nix
    ../../modules/home/msgvault.nix # INERT: programs.msgvault.enable = false (default)
    ../../modules/home/python.nix
    ../../modules/home/terminal/kitty.nix
    ../../modules/home/thunar.nix
    ../../modules/home/xdg.nix
    # Hermes Agent
    ../../modules/home/daemonturgy/hermes/default.nix
  ];

  home = {
    username = "zk";
    homeDirectory = "/home/zk";
    stateVersion = "25.11";

    # User packages
    packages = with pkgs; [
      # Apps
      altus
      gimp
      vlc
      zathura
      lmstudio
      sonicPiPinned

      # Dev Tools
      cargo
      gcc
      gnumake
      go
      rustc
      godot
      xdg-desktop-portal-gtk

      # LSP servers (in PATH for Zed/editors with nix-ld)
      nixd
      nil
      nixfmt

      # System management
      (import ../../modules/home/cli/zcli.nix { inherit pkgs; })

      (writeShellApplication {
        name = "pi";
        runtimeInputs = [ nodejs ];
        text = ''
          set -euo pipefail
          exec npx --yes @mariozechner/pi-coding-agent "$@"
        '';
      })

      (writeShellApplication {
        name = "fzf-emoji";
        runtimeInputs = [
          fzf
          jq
          wl-clipboard
          curl
          coreutils
        ];
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
    ];

    activation.ensureLocalBin = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.local/bin"
      chmod 0755 "$HOME/.local/bin"
    '';

    file = {
      # Minimal zshrc for Electron app shell environment resolution.
      ".zshrc".text = ''
        export PATH="$HOME/.local/bin:$HOME/.nix-profile/bin:/etc/profiles/per-user/zk/bin:$PATH"
      '';

      ".face".source = ../../assets/nxiz-face.png;

      ".config/monitors.xml".source = ./nxiz-monitors.xml;
    };
  };

  programs.home-manager.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableNushellIntegration = true;
  };

  xdg.desktopEntries.gimp = {
    name = "GIMP";
    genericName = "Image Editor";
    comment = "Create images and edit photographs";
    exec = "gimp %U";
    icon = "gimp";
    terminal = false;
    type = "Application";
    categories = [
      "Graphics"
      "2DGraphics"
      "RasterGraphics"
      "GTK"
    ];
    settings = {
      Keywords = "GIMP;graphic;design;illustration;painting;";
    };
  };
}
