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

    # OpenRGB 1.0 reads OpenRGB.json, Configuration.json, and profiles/*.json.
    # A .orp or .ors left in the config directory is renamed to .bak on startup,
    # and the effects plugin skips a legacy effect file when a profile of the
    # same name already exists. Keep those legacy files in the repo only.
    ln -sf "${repoPath}/OpenRGB.json" "${confPath}/OpenRGB.json"
    ln -sf "${repoPath}/Configuration.json" "${confPath}/Configuration.json"
    rm -f "${confPath}/boot.orp" "${confPath}/off.orp" "${confPath}/sunset.orp" "${confPath}/sizes.ors" \
      "${confPath}/boot.orp.bak" "${confPath}/off.orp.bak" "${confPath}/sunset.orp.bak" "${confPath}/sizes.ors.bak"
    if [ -L "${confPath}/plugins/settings/effect-profiles" ]; then
      rm -f "${confPath}/plugins/settings/effect-profiles"
    fi

    # Symlink plugin settings file
    ln -sf "${repoPath}/plugins/settings/EffectSettings.json" "${confPath}/plugins/settings/EffectSettings.json"

    # Profiles are what the 1.0 UI lists, including effect stacks saved in them.
    if [ -d "${confPath}/profiles" ] && [ ! -L "${confPath}/profiles" ]; then
      rm -rf "${confPath}/profiles"
    fi
    ln -sfn "${repoPath}/profiles" "${confPath}/profiles"

    # Skill is not written by the GUI. Point the whole directory at the flake.
    if [ -d "${confPath}/.agents" ] && [ ! -L "${confPath}/.agents" ]; then
      rm -rf "${confPath}/.agents"
    fi
    ln -sfn "${agentsPath}" "${confPath}/.agents"
  '';
}
