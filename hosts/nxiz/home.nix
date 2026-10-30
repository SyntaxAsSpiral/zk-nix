# User environment: identity, apps, system utils
{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ../../shared/home/daemon-profile.nix
    ../../shared/home/nushell.nix
    ../../shared/home/xdg.nix
    ../../shared/home/fastfetch/default.nix
    ../../shared/home/fun.nix
    ../../shared/home/gh.nix
    ../../shared/home/otter-launcher.nix
    ../../shared/home/zcli.nix
    ../../shared/home/editors/nano.nix
    ../../shared/home/yazi/default.nix
    ../../shared/home/editors/zed.nix
    ../../shared/home/pi/default.nix

    ../../shared/home/browser/firefox.nix
    ../../shared/home/gtk.nix
    ../../shared/home/icons.nix
    ../../shared/home/spotify.nix
    ../../shared/home/thunar.nix
    ../../shared/home/fzf-emoji.nix

    ../../shared/home/fsel.nix
    ../../shared/home/msgvault.nix
    ../../shared/home/python.nix

    ./desk-env/obsidian.nix
    ./desk-env/hyprland/hyprland.nix
    ./desk-env/awww.nix
    ./desk-env/lmstudio-autorun.nix
    ./desk-env/kitty.nix
  ];

  programs = {
    home-manager.enable = true;

    # Vault archiver on both vault hosts (headless-by-design; see adeck)
    msgvault.enable = true;

    direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableNushellIntegration = true;
    };
  };

  systemd.user.services.grok-bot = {
    Unit = {
      Description = "Grok Bot";
      After = [ "hyprland-session.target" ];
      PartOf = [ "hyprland-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.llm-agents.grok-bot}/bin/grok-bot";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };

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
      # Upstream checkPhase starts jackd, which the sandbox cannot do.
      # Ruby 3.3 and Boost 1.86 now come from nixpkgs itself.
      (sonic-pi.overrideAttrs (_old: {
        doCheck = false;
      }))
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
