# NixOS configuration for quita — laptop terminal. Core, no display stack yet: the
# desktop (nixarchy's Hyprland) is added once the trial settles.
# No NVIDIA, Steam, or packages.nix (its playwright browsers are the bulk of that set).
{ lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix

    ../../shared/system/core.nix
    ../../shared/system/boot.nix
    ../../shared/system/user.nix
    ../../shared/system/services.nix
    ../../shared/system/esofonts.nix
  ];

  my.host = "quita";

  # No Steam, so no 32-bit audio stack.
  services.pipewire.alsa.support32Bit = lib.mkForce false;

  # No performance.nix here, so zram is set per host. The swapfile (@swap) comes with the
  # installer's hardware-configuration.nix.
  zramSwap.enable = true;

  programs = {
    thunar = {
      enable = true;
      plugins = with pkgs; [
        thunar-volman
        thunar-archive-plugin
      ];
    };
    nm-applet.enable = true;
  };

  environment.systemPackages = with pkgs; [
    bluetuith
    networkmanagerapplet
  ];

  system.stateVersion = "25.11";
}
