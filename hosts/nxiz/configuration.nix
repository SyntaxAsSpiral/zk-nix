# NixOS configuration for nxiz
{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/core.nix
    ../../modules/profiles/desktop.nix

    # Login manager playground modules (inert by default).
    # Activate explicitly via one toggle at a time:
    #   my.login.ly.enable = true;
    #   my.login.greetd.enable = true;
    ../../modules/ly.nix
    ../../modules/greetd.nix
  ];

  my.host = "nxiz";

  # Super I/O fan/RPM sensors (case fans on motherboard headers);
  # harmless no-op if the board's chip isn't Nuvoton
  boot.kernelModules = [ "nct6775" ];

  # nxiz-only services
  services.gnome.gnome-keyring.enable = true;

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
  };

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

  system.stateVersion = "25.11";
}
