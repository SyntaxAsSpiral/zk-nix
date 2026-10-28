# NixOS configuration for nxiz
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix

    ../../shared/system/system.nix
    ../../shared/system/boot.nix
    ../../shared/system/nh.nix
    ../../shared/system/user.nix
    ../../shared/system/secrets.nix
    ../../shared/system/services.nix
    ../../shared/system/storage.nix
    ../../shared/system/packages.nix
    ../../shared/system/networking.nix
    ../../shared/system/fonts.nix
    ../../shared/system/ssh-identity.nix
    ../../shared/system/shell.nix

    ../../shared/system/nvidia.nix
    ../../shared/system/steam.nix
    ../../shared/system/performance.nix

    # Login manager playground (inert by default).
    # Activate explicitly: my.login.greetd.enable = true;
    ./greetd.nix
  ];

  my.host = "nxiz";
  my.performance.enable = true;

  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-volman
      thunar-archive-plugin
    ];
  };

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # Super I/O fan/RPM sensors (case fans on motherboard headers);
  # harmless no-op if the board's chip isn't Nuvoton
  boot.kernelModules = [ "nct6775" ];

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
  };

  # The pinned 0.56.2 bin/Hyprland is a wrapProgram script. The capability
  # wrapper must target an ELF, so point it at the unwrapped binary.
  security.wrappers.Hyprland.source =
    lib.mkForce "${config.programs.hyprland.package}/bin/.Hyprland-wrapped";

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-hyprland
    ];
  };

  # Keep Wake-on-LAN enabled on the wired NIC.
  systemd.services.wol-enp10s0 = {
    description = "Enable Wake-on-LAN on enp10s0";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-pre.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.ethtool}/bin/ethtool -s enp10s0 wol g
    '';
  };

  environment.systemPackages = [
    pkgs.llm-agents.grok
    pkgs.llm-agents.grok-bot
    pkgs.llm-agents.pi
    pkgs.llm-agents.gemini-cli
    pkgs.llm-agents.crush
    # Numtide's cached builds; shared-nixpkgs would recompile these on every bump.
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.herdr
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.beads
  ];

  system.stateVersion = "25.11";
}
