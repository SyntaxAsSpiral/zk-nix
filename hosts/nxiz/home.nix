# User environment: identity, apps, system utils
{
  config,
  pkgs,
  inputs,
  ...
}:

let
  pinnedSonicPiPkgs = inputs.nixpkgs-sonic-pi.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  sonicPiPinned =
    (pinnedSonicPiPkgs.sonic-pi.override {
      ruby = pinnedSonicPiPkgs.ruby_3_3;
      boost = pinnedSonicPiPkgs.boost186;
    }).overrideAttrs
      (old: {
        doCheck = false;
        meta = old.meta // {
          broken = false;
        };
      });
in

{
  imports = [
    ../../modules/home/profiles/base.nix
    ../../modules/home/profiles/desktop.nix

    # nxiz-specific
    ../../modules/home/cli/fastfetch/eso-fetch.nix
    ../../modules/home/editors/obsidian.nix
    ../../modules/home/fsel.nix
    ../../modules/home/otter-launcher/otter-launcher.nix
    ../../modules/home/hyprland/hyprland.nix
    ../../modules/home/awww.nix
    ../../modules/home/daemonturgy/mods/mods.nix
    ../../modules/home/daemonturgy/lmstudio/nxiz/default.nix
    ../../modules/home/msgvault.nix
    ../../modules/home/python.nix
    ../../modules/home/terminal/kitty.nix
  ];

  # Vault archiver on both vault hosts (headless-by-design; see adeck)
  programs.msgvault.enable = true;

  home = {
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
      libreoffice

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

      (writeShellApplication {
        name = "pi";
        runtimeInputs = [ nodejs ];
        text = ''
          set -euo pipefail
          exec npx --yes @earendil-works/pi-coding-agent "$@"
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
