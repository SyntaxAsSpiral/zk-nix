# XDG base directories, user-dirs, and MIME defaults
# Shared across all hosts — mesh paths via NFS automount
{ config, lib, osConfig, ... }:

let
  home = config.home.homeDirectory;

  # ── Common directories (all hosts) ──
  # Local dirs that every host gets regardless of role
  commonDirs = {
    desktop = "${home}/Desktop";
    download = "${home}/Downloads";
    publicShare = "${home}/Public";
    templates = "${home}/Templates";
    extraConfig = {
      IMAGES = "${home}/Images";
      WALLPAPERS = "${home}/Images/wallpapers";
      SCREENSHOT = "${home}/Images/screenshots";
    };
  };

  # ── Mesh directories ──
  # Media lives on zrrh:/mnt/media (local there, NFS automount elsewhere)
  # Documents live on nxiz:/mnt/repository (local there, NFS automount elsewhere)
  meshDirs = {
    documents = "/mnt/repository/zk-docs";
    music = "/mnt/media/Music";
    pictures = "/mnt/media/Pictures";
    videos = "/mnt/media/Videos";
  };

  # ── Per-host extensions ──
  perHost = {
    nxiz = {
      dirs = {
        extraConfig = {
          ARCHIVE = "/mnt/archive";
          PROJECTS = "/mnt/repository";
          BOOK = "/mnt/repository/zk-docs/reading";
          COMICS = "/mnt/media/Comics";
          VM = "${home}/Machines";
          NOTES = "${home}/Notes";
        };
      };
      localDirs = [
        "${home}/Machines"
        "${home}/Notes"
      ];
      sessionVariables = {
        BROWSER = "firefox";
        EDITOR = "nvim";
        VISUAL = "nvim";
        HYPRSHOT_DIR = "${home}/Images/screenshots";
      };
      mimeApps = {
        "text/plain" = "kiro.desktop";
        "text/x-shellscript" = "kiro.desktop";
        "application/x-yaml" = "kiro.desktop";
        "application/json" = "kiro.desktop";
        "application/toml" = "kiro.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/ftp" = "firefox.desktop";
        "x-scheme-handler/file" = "firefox.desktop";
        "x-scheme-handler/about" = "firefox.desktop";
        "x-scheme-handler/chrome" = "firefox.desktop";
      };
    };

    adeck = {
      dirs = {
        extraConfig = {};
      };
      localDirs = [];
      sessionVariables = {
        EDITOR = "nvim";
      };
      mimeApps = {};
    };

    zrrh = {
      dirs = {
        extraConfig = {};
      };
      localDirs = [];
      sessionVariables = {
        BROWSER = "firefox";
        EDITOR = "nvim";
      };
      mimeApps = {
        "inode/directory" = "thunar.desktop";
        "x-scheme-handler/file" = "thunar.desktop";
        "image/png" = "firefox.desktop";
        "image/jpeg" = "firefox.desktop";
        "image/gif" = "firefox.desktop";
        "image/webp" = "firefox.desktop";
        "image/svg+xml" = "firefox.desktop";
        "application/pdf" = "firefox.desktop";
        "x-scheme-handler/steam" = "steam.desktop";
        "x-scheme-handler/steamlink" = "steam.desktop";
      };
    };
  };

  h = perHost.${osConfig.my.host};

  # Per-host wallpaper source from repo assets
  wpSource = {
    nxiz  = ../../assets/wallpapers/wp-nxiz;
    adeck = ../../assets/wallpapers/wp-adeck;
    zrrh  = ../../assets/wallpapers/wp-zrrh;
  };

in {
  xdg.enable = true;
  xdg.mime.enable = true;
  xdg.mimeApps.enable = true;

  xdg.configHome = "${home}/.config";
  xdg.dataHome = "${home}/.local/share";
  xdg.cacheHome = "${home}/.cache";

  xdg.userDirs = commonDirs // meshDirs // h.dirs // {
    enable = true;
    createDirectories = false;
    extraConfig = commonDirs.extraConfig // h.dirs.extraConfig;
  };

  # Create only local dirs — mesh paths exist on their owning host,
  # NFS automount handles the rest at access time
  home.activation.createLocalXdgDirs = config.lib.dag.entryAfter [ "writeBoundary" ] (
    ''
      mkdir -p "${home}/Desktop"
      mkdir -p "${home}/Downloads"
      mkdir -p "${home}/Public"
      mkdir -p "${home}/Templates"
      mkdir -p "${home}/Images/wallpapers"
      mkdir -p "${home}/Images/screenshots"
    '' + lib.concatMapStringsSep "\n" (d: ''mkdir -p "${d}"'') h.localDirs
  );

  home.sessionVariables = h.sessionVariables;

  xdg.mimeApps.defaultApplications = h.mimeApps;

  # Populate ~/Images/wallpapers with per-host wallpaper set from repo
  home.file."Images/wallpapers".source = wpSource.${osConfig.my.host};
}
