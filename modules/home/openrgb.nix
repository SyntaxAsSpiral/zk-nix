# OpenRGB Home Manager configuration
# Creates mutable symlinks from the flake repo to ~/.config/OpenRGB
# This allows the GUI to write changes directly back to the repo files
{ config, ... }:

let
  repoPath = "/etc/nixos/modules/openrgb/config";
  agentsPath = "/etc/nixos/modules/openrgb/.agents";
  confPath = "${config.home.homeDirectory}/.config/OpenRGB";
in
{
  home.activation.openrgbConfig = config.lib.dag.entryAfter [ "linkGeneration" ] ''
    # Ensure parent directories exist
    mkdir -p "${confPath}/plugins/settings"
    mkdir -p "${confPath}/logs"

    # 1.0rc3.1 loads the .orp color profiles, sizes, and the effects directory.
    ln -sf "${repoPath}/OpenRGB.json" "${confPath}/OpenRGB.json"
    ln -sf "${repoPath}/boot.orp" "${confPath}/boot.orp"
    ln -sf "${repoPath}/off.orp" "${confPath}/off.orp"
    ln -sf "${repoPath}/sunset.orp" "${confPath}/sunset.orp"
    ln -sf "${repoPath}/sizes.ors" "${confPath}/sizes.ors"
    if [ -L "${confPath}/profiles" ]; then
      rm -f "${confPath}/profiles"
    fi

    # Symlink plugin settings file
    ln -sf "${repoPath}/plugins/settings/EffectSettings.json" "${confPath}/plugins/settings/EffectSettings.json"

    # Symlink the ENTIRE effect-profiles directory
    # Force remove existing directory if it's not a symlink to prevent nesting
    if [ -d "${confPath}/plugins/settings/effect-profiles" ] && [ ! -L "${confPath}/plugins/settings/effect-profiles" ]; then
      rm -rf "${confPath}/plugins/settings/effect-profiles"
    fi
    ln -sfn "${repoPath}/plugins/settings/effect-profiles" "${confPath}/plugins/settings/effect-profiles"

    # Skill is not written by the GUI. Point the whole directory at the flake.
    if [ -d "${confPath}/.agents" ] && [ ! -L "${confPath}/.agents" ]; then
      rm -rf "${confPath}/.agents"
    fi
    ln -sfn "${agentsPath}" "${confPath}/.agents"
  '';
}
