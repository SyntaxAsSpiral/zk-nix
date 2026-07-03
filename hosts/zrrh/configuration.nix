# NixOS configuration for zrrh — local inference + media/gaming workstation
{ pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/core.nix
    ../../modules/profiles/desktop.nix
    ../../modules/openrgb
    inputs.pia.nixosModules.default
  ];

  my.host = "zrrh";

  programs = {
    # Compositor
    niri.enable = true;
    xwayland.enable = true;

    # Gaming extras
    gamemode.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-wlr ];
  };

  # Earlier NVIDIA handoff for sharper boot graphics
  boot.initrd.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
    "amdgpu" # Load after nvidia to prioritize card indexing
  ];

  # Force console to the NVIDIA card (card1) to ensure Plymouth visibility
  boot.kernelParams = [ "fbcon=map:1" ];

  # GPU Control (AMD/NVIDIA)
  services.lact.enable = true;

  environment.systemPackages = with pkgs; [
    mangohud
    vkbasalt
    vlc
    qbittorrent
    xwayland-satellite
    llama-cpp
    llm-agents.pi
    llm-agents.codex
    llm-agents.gemini-cli
    llm-agents.crush
  ];

  system.stateVersion = "25.11";
}
