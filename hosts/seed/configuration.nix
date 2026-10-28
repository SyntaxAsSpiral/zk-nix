# NixOS configuration for seed — portable x86_64 UEFI stick. It is the core: copy it to
# start a host, then add on. It is also the rescue stick. Boot the target, join GBZ Wi-Fi
# and Tailscale, SSH in, then partition and install, or run `zcli deploy seed` to deploy itself.
# core.nix is the shared base. packages.nix and the NVIDIA/Steam desktop
# blew the stick out to 8.5 GiB, so they are not in this list.
# Console only: no display server.
{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../shared/system/core.nix
    ../../shared/system/boot.nix
  ];

  my.host = "seed";

  # Portable stick: never write NVRAM boot entries on whatever box it is plugged into.
  # bootctl still installs the removable fallback EFI/BOOT/BOOTX64.EFI.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  documentation.enable = false;

  users.users.zk = {
    extraGroups = [ "disk" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBfoVdWpimtBi0htouhMDsD1NXuKbIAusgzB1dxYDW4z"
    ];
  };

  environment.systemPackages = with pkgs; [
    parted
    gptfdisk
    dosfstools
    e2fsprogs
    btrfs-progs
    xfsprogs
    cryptsetup
    nvme-cli
    smartmontools
    efibootmgr
    pciutils
    usbutils
    rsync
    curl
    nixos-install-tools
  ];

  system.stateVersion = "25.11";
}
