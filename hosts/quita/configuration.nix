# NixOS configuration for quita — laptop terminal. Core plus nixarchy (Omarchy on NixOS), on trial.
# No NVIDIA, Steam, or packages.nix (its playwright browsers are the bulk of that set).
{ lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./nixarchy-apps.nix

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

  # nixarchy, as the doctor asked for it on this machine. The Home Manager half is in home.nix.
  programs.nixarchy = {
    enable = true;
    user = "zk";
  };
  hardware.graphics.extraPackages = with pkgs; [ intel-media-driver ];

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
