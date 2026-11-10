# quita: bare NixOS, installed from seed. No flake yet. Tailscale first, then nixarchy.
{ pkgs, nixarchy, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 5;
    };
    efi.canTouchEfiVariables = true;
  };

  networking = {
    hostName = "quita";
    networkmanager.enable = true;
  };

  services = {
    openssh.enable = true;
    tailscale = {
      enable = true;
      useRoutingFeatures = "client";
      extraUpFlags = [ "--ssh" ];
    };
  };
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  zramSwap.enable = true;

  time.timeZone = "America/Los_Angeles";

  users.users.zk = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBfoVdWpimtBi0htouhMDsD1NXuKbIAusgzB1dxYDW4z"
    ];
  };
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [ git vim ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # nixarchy: Omarchy for NixOS. Doctor output, 2026-11-09.
  programs.nixarchy = {
    enable = true;
    user = "zk";
  };
  hardware.graphics.extraPackages = with pkgs; [ intel-media-driver ];

  home-manager.users.zk = {
    imports = [ nixarchy.homeManagerModules.nixarchy ];
    programs.nixarchy.enable = true;
    services.nixi.enable = false; # nixi is what pulls in codex, which does not build
    home.stateVersion = "25.11";
  };

  system.stateVersion = "25.11";
}
