# NixOS configuration for jump — headless USB rescue stick.
# Boots on any x86_64 UEFI box, joins GBZ Wi-Fi, Tailscale, SSH. No HM, no desktop.
{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/core.nix
  ];

  my.host = "jump";

  # Portable stick: never write NVRAM boot entries on whatever box it is plugged into.
  # bootctl still installs the removable fallback EFI/BOOT/BOOTX64.EFI.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  # LAN SSH before Tailscale is logged in (desktop hosts rely on Tailscale SSH).
  users.users.zk.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBfoVdWpimtBi0htouhMDsD1NXuKbIAusgzB1dxYDW4z"
  ];

  # Rescue toolkit
  environment.systemPackages = with pkgs; [
    parted
    gptfdisk
    nvme-cli
    smartmontools
    rsync
    tmux
  ];

  system.stateVersion = "25.11";
}
