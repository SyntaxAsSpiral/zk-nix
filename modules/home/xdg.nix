# XDG base directories, user-dirs, and MIME defaults
# Shared across all hosts — remote content via Taildrive bookmarks
{
  config,
  lib,
  osConfig,
  ...
}:

let
  home = config.home.homeDirectory;

  # ── Common directories (all hosts) ──
  commonDirs = {
    download = "${home}/Downloads";
    extraConfig = {
      IMAGES = "${home}/Images";
      WALLPAPERS = "${home}/Images/wallpapers";
      SCREENSHOT = "${home}/Images/screenshots";
    };
  };

  # ── Desktop-role XDG dirs ──
  desktopDirs = {
    desktop = "${home}/Desktop";
    publicShare = "${home}/Public";
    templates = "${home}/Templates";
  };

  # ── Mesh directories ──
  # Only set XDG user dirs for paths that are local to the host.
  # Remote content is accessed via Taildrive bookmarks in Thunar.
  perHost = {
    nxiz = {
      dirs = desktopDirs // {
        documents = "/mnt/repository/zk-docs";
        extraConfig = {
          ARCHIVE = "/mnt/archive";
          PROJECTS = "/mnt/repository";
          BOOK = "/mnt/repository/zk-docs/reading";
        };
      };
      localDirs = [
        "${home}/Desktop"
        "${home}/Public"
        "${home}/Templates"
        "${home}/Machines"
        "${home}/Notes"
      ];
      sessionVariables = {
        BROWSER = "firefox";
        EDITOR = "nano";
        VISUAL = "zeditor";
        HYPRSHOT_DIR = "${home}/Images/screenshots";
      };
      mimeApps = {
        "inode/directory" = "thunar.desktop";
        "x-scheme-handler/file" = "thunar.desktop";
        "x-scheme-handler/lmstudio" = "lm-studio.desktop";
        "audio/wav" = "vlc.desktop";
        "audio/x-wav" = "vlc.desktop";
        "audio/mpeg" = "vlc.desktop";
        "audio/mp4" = "vlc.desktop";
        "audio/aac" = "vlc.desktop";
        "video/mp4" = "vlc.desktop";
        "text/plain" = "dev.zed.Zed.desktop";
        "text/x-shellscript" = "dev.zed.Zed.desktop";
        "application/x-yaml" = "dev.zed.Zed.desktop";
        "application/json" = "dev.zed.Zed.desktop";
        "application/toml" = "dev.zed.Zed.desktop";
        "application/pdf" = "org.pwmt.zathura.desktop";

        # LibreOffice documents
        "application/msword" = "writer.desktop";
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "writer.desktop";
        "application/vnd.openxmlformats-officedocument.wordprocessingml.template" = "writer.desktop";
        "application/vnd.ms-word.document.macroEnabled.12" = "writer.desktop";
        "application/rtf" = "writer.desktop";
        "application/vnd.oasis.opendocument.text" = "writer.desktop";
        "application/vnd.ms-excel" = "calc.desktop";
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "calc.desktop";
        "application/vnd.oasis.opendocument.spreadsheet" = "calc.desktop";
        "application/vnd.ms-powerpoint" = "impress.desktop";
        "application/vnd.openxmlformats-officedocument.presentationml.presentation" = "impress.desktop";
        "application/vnd.oasis.opendocument.presentation" = "impress.desktop";

        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/ftp" = "firefox.desktop";
        "x-scheme-handler/about" = "firefox.desktop";
        "x-scheme-handler/chrome" = "firefox.desktop";
      };
    };

    adeck = {
      dirs = {
        extraConfig = { };
      };
      localDirs = [
        "${home}/Documents"
        "${home}/Projects"
      ];
      sessionVariables = {
        EDITOR = "nano";
        VISUAL = "zeditor";
      };
      mimeApps = { };
    };

    zrrh = {
      dirs = desktopDirs // {
        music = "/mnt/media/Music";
        pictures = "/mnt/media/Pictures";
        videos = "/mnt/media/Videos";
        extraConfig = { };
      };
      localDirs = [
        "${home}/Desktop"
      ];
      sessionVariables = {
        BROWSER = "firefox";
        EDITOR = "nano";
        VISUAL = "zeditor";
      };
      mimeApps = {
        "inode/directory" = "thunar.desktop";
        "x-scheme-handler/file" = "thunar.desktop";
        "image/png" = "firefox.desktop";
        "image/jpeg" = "firefox.desktop";
        "image/gif" = "firefox.desktop";
        "image/webp" = "firefox.desktop";
        "image/svg+xml" = "firefox.desktop";
        "application/pdf" = "org.pwmt.zathura.desktop";
        "x-scheme-handler/steam" = "steam.desktop";
        "x-scheme-handler/steamlink" = "steam.desktop";
        "x-scheme-handler/lmstudio" = "lm-studio.desktop";
      };
    };
  };

  h = perHost.${osConfig.my.host};

  # Per-host wallpaper source from repo assets
  wpSource = {
    nxiz = ../../assets/wallpapers/wp-nxiz;
    adeck = ../../assets/wallpapers/wp-adeck;
    zrrh = ../../assets/wallpapers/wp-zrrh;
  };

in
{
  xdg = {
    enable = true;
    mime.enable = true;
    mimeApps.enable = true;
    mimeApps.defaultApplications = h.mimeApps;

    configHome = "${home}/.config";
    dataHome = "${home}/.local/share";
    cacheHome = "${home}/.cache";

    userDirs =
      commonDirs
      // h.dirs
      // {
        enable = true;
        createDirectories = false;
        setSessionVariables = true; # Keep legacy (stateVersion < 26.05)
        extraConfig = commonDirs.extraConfig // h.dirs.extraConfig;
      };
  };

  home = {
    # Create only local dirs — remote content accessed via Taildrive
    activation.createLocalXdgDirs = config.lib.dag.entryAfter [ "writeBoundary" ] (
      ''
        mkdir -p "${home}/Downloads"
        mkdir -p "${home}/Images/wallpapers"
        mkdir -p "${home}/Images/screenshots"
      ''
      + lib.concatMapStringsSep "\n" (d: ''mkdir -p "${d}"'') h.localDirs
    );

    sessionVariables = h.sessionVariables;

    # Populate ~/Images/wallpapers with per-host wallpaper set from repo
    file."Images/wallpapers".source = wpSource.${osConfig.my.host};
  };
}
