# Thunar file manager — shared module with per-host config
#
# System-level (programs.thunar) is in host configuration.nix.
# This module handles home-manager: packages, thunarrc, bookmarks,
# custom actions, and exo helpers.
{
  pkgs,
  lib,
  osConfig,
  ...
}:

let
  tailnet = "tail293e98.ts.net";

  # Taildrive WebDAV base for bookmarks
  # Thunar/GVFS can browse dav:// URIs natively
  # Taildrive serves plain HTTP on 100.100.100.100:8080 (encrypted by WireGuard underneath)
  dav = host: share: "dav://100.100.100.100:8080/${tailnet}/${host}/${share}";

  perHost = {
    nxiz = {
      # Bookmarks: remote drives via Taildrive + local paths
      bookmarks = [
        "${dav "zrrh" "media"} 🎬 Media (zrrh)"
        "${dav "zrrh" "games"} 🎮 Games (zrrh)"
        "${dav "adeck" "vault"} 🔒 Vault (adeck)"
        "file:///mnt/repository 📂 Repository"
        "file:///mnt/archive 📦 Archive"
        "file:///home/zk/Downloads ⬇ Downloads"
        "file:///home/zk/Images 🖼 Images"
      ];
      thunarrc = {
        LastView = "ThunarIconView";
        LastSidePane = "ThunarShortcutsPane";
        LastLocationBar = "ThunarLocationButtons";
        LastMenubarVisible = "TRUE";
        LastStatusbarVisible = "TRUE";
        MiscShowHiddenFiles = "TRUE";
        MiscImagePreviewMode = "THUNAR_IMAGE_PREVIEW_MODE_EMBEDDED";
        MiscThumbnailMode = "THUNAR_THUMBNAIL_MODE_ALWAYS";
        MiscShowThumbnailsInTree = "TRUE";
        MiscFileSizeBinary = "TRUE";
        MiscSingleClick = "FALSE";
        MiscFolderItemCount = "THUNAR_FOLDER_ITEM_COUNT_ALWAYS";
        MiscDateStyle = "THUNAR_DATE_STYLE_ISO";
        MiscRecursiveSearch = "THUNAR_RECURSIVE_SEARCH_ALWAYS";
      };
      terminal = "kitty";
    };

    zrrh = {
      bookmarks = [
        "${dav "nxiz" "repository"} 📂 Repository (nxiz)"
        "${dav "nxiz" "archive"} 📦 Archive (nxiz)"
        "${dav "adeck" "vault"} 🔒 Vault (adeck)"
        "file:///mnt/media 🎬 Media"
        "file:///mnt/games 🎮 Games"
        "file:///home/zk/Downloads ⬇ Downloads"
        "file:///home/zk/Images 🖼 Images"
      ];
      thunarrc = {
        LastView = "ThunarIconView";
        LastSidePane = "ThunarShortcutsPane";
        LastLocationBar = "ThunarLocationButtons";
        LastMenubarVisible = "TRUE";
        LastStatusbarVisible = "TRUE";
        MiscShowHiddenFiles = "TRUE";
        MiscImagePreviewMode = "THUNAR_IMAGE_PREVIEW_MODE_EMBEDDED";
        MiscThumbnailMode = "THUNAR_THUMBNAIL_MODE_ALWAYS";
        MiscShowThumbnailsInTree = "TRUE";
        MiscFileSizeBinary = "TRUE";
        MiscSingleClick = "FALSE";
        MiscFolderItemCount = "THUNAR_FOLDER_ITEM_COUNT_ALWAYS";
        MiscDateStyle = "THUNAR_DATE_STYLE_ISO";
        MiscRecursiveSearch = "THUNAR_RECURSIVE_SEARCH_ALWAYS";
      };
      terminal = "ghostty";
    };
  };

  h = perHost.${osConfig.my.host};

  # Render thunarrc from attrset
  thunarrcText = lib.concatStringsSep "\n" (
    [ "[Configuration]" ] ++ (lib.mapAttrsToList (k: v: "${k}=${v}") h.thunarrc)
  );

  # Render bookmarks (one URI per line, GTK bookmark format)
  bookmarksText = lib.concatStringsSep "\n" h.bookmarks;

  # Custom actions (uca.xml) — shared across hosts, terminal varies
  ucaXml = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <actions>
      <action>
        <icon>utilities-terminal</icon>
        <name>Open Terminal Here</name>
        <submenu></submenu>
        <unique-id>open-terminal-here</unique-id>
        <command>${h.terminal} --working-directory %f</command>
        <description>Open terminal in this directory</description>
        <range></range>
        <patterns>*</patterns>
        <directories/>
      </action>
      <action>
        <icon>text-editor</icon>
        <name>Edit in Neovim</name>
        <submenu></submenu>
        <unique-id>edit-in-nvim</unique-id>
        <command>${h.terminal} -e nvim %f</command>
        <description>Open file in Neovim</description>
        <range>*</range>
        <patterns>*</patterns>
        <text-files/>
      </action>
    </actions>
  '';

in
{
  home.packages = with pkgs; [
    xfce4-exo
    tumbler
    glib # gio for trash/mount operations
  ];

  home.file = {
    ".config/Thunar/thunarrc".text = thunarrcText;
    ".config/Thunar/uca.xml".text = ucaXml;
    ".config/gtk-3.0/bookmarks".text = bookmarksText;
  };
}
