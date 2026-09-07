# NixOS configuration for zrrh — local inference + media/gaming workstation
{ pkgs, inputs, ... }:

let
  # CUDA inference packages from the dedicated pinned input (see flake.nix:
  # nixpkgs-llm) — insulated from routine nixpkgs bumps.
  pkgsLlm = import inputs.nixpkgs-llm {
    system = "x86_64-linux";
    config = {
      allowUnfree = true;
      cudaSupport = true;
      # Only compile kernels for the 4090 (Ada, sm_89) — several-fold
      # faster builds than the default all-architectures fatbin
      cudaCapabilities = [ "8.9" ];
    };
  };
in
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

  # Super I/O fan/RPM sensors (AIO pump + case fans on motherboard headers)
  boot.kernelModules = [ "nct6775" ];

  # GPU Control (AMD/NVIDIA)
  # 4090 capped at 330W by default (inference is memory-bound; <7% tokens/s cost).
  # Gamemode-launched games auto-switch to the uncapped Gaming profile.
  # Steam does NOT trigger this by itself — per game, set Steam Launch Options to:
  #   gamemoderun %command%
  # Games launched without it simply run under the 330W cap.
  services.lact = {
    enable = true;
    settings = {
      version = 7;
      daemon = {
        log_level = "info";
        admin_group = "wheel";
        disable_clocks_cleanup = false;
      };
      apply_settings_timer = 5;
      auto_switch_profiles = true;
      gpus."10DE:2684-1458:40BF-0000:01:00.0".power_cap = 330.0;
      profiles.Gaming = {
        rule.type = "gamemode";
        gpus."10DE:2684-1458:40BF-0000:01:00.0".power_cap = 450.0;
      };
    };
  };

  # lactd shells out to `sudo -u zk busctl --user` for gamemode detection;
  # NixOS sudo lives in /run/wrappers/bin which is not in the unit's default PATH
  systemd.services.lactd.path = [ "/run/wrappers" ];

  environment.systemPackages = with pkgs; [
    mangohud
    vkbasalt
    vlc
    qbittorrent
    xwayland-satellite
    pkgsLlm.llama-cpp
    llm-agents.pi
    llm-agents.codex
    llm-agents.gemini-cli
    llm-agents.crush
    llm-agents.grok
  ];

  system.stateVersion = "25.11";
}
