# OpenRGB Home Manager configuration
# Creates mutable symlinks from the flake repo to ~/.config/OpenRGB
# This allows the GUI to write changes directly back to the repo files
{ config, ... }:

let
  repoPath = "/etc/nixos/modules/openrgb/config";
  confPath = "${config.home.homeDirectory}/.config/OpenRGB";
in {
  home.activation.openrgbConfig = config.lib.dag.entryAfter [ "linkGeneration" ] ''
    # Ensure parent directories exist
    mkdir -p "${confPath}/plugins/settings"
    mkdir -p "${confPath}/logs"

    # Symlink top-level config and profiles
    ln -sf "${repoPath}/OpenRGB.json" "${confPath}/OpenRGB.json"
    ln -sf "${repoPath}/boot.orp" "${confPath}/boot.orp"
    ln -sf "${repoPath}/off.orp" "${confPath}/off.orp"
    ln -sf "${repoPath}/sunset.orp" "${confPath}/sunset.orp"
    ln -sf "${repoPath}/sizes.ors" "${confPath}/sizes.ors"

    # Symlink plugin settings file
    ln -sf "${repoPath}/plugins/settings/EffectSettings.json" "${confPath}/plugins/settings/EffectSettings.json"

    # Symlink the ENTIRE effect-profiles directory
    # Force remove existing directory if it's not a symlink to prevent nesting
    if [ -d "${confPath}/plugins/settings/effect-profiles" ] && [ ! -L "${confPath}/plugins/settings/effect-profiles" ]; then
      rm -rf "${confPath}/plugins/settings/effect-profiles"
    fi
    ln -sfn "${repoPath}/plugins/settings/effect-profiles" "${confPath}/plugins/settings/effect-profiles"
  '';
}
