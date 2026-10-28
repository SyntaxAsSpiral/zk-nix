# NixOS configuration for tm20 — Pi 3B+ print-host appliance.
# Minimal: firmware, NM, Tailscale, SSH, Epson USB. No desktop; Home-Manager carries the shell only.
{
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    ../../shared/system/core.nix
    ./print-receiver.nix
  ];

  my.host = "tm20";

  sdImage.compressImage = false;
  # After flashing, copy secrets/ to /etc/nixos/secrets on the mounted root
  # partition before first boot. Activation installs host keys and credentials.
  boot.zfs.forceImportRoot = false;
  # Pi 3B+ onboard BT shares the WiFi chip. We do not run BlueZ; the
  # kernel still probes hci_uart and times out on the console.
  boot.blacklistedKernelModules = [
    "bluetooth"
    "btbcm"
    "btqca"
    "btsdio"
    "hci_uart"
  ];

  hardware.enableRedistributableFirmware = true;

  zramSwap.enable = true;

  users.groups.plugdev = { };
  users.users.zk = {
    extraGroups = [
      "plugdev"
      "dialout"
    ];
    linger = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBfoVdWpimtBi0htouhMDsD1NXuKbIAusgzB1dxYDW4z"
    ];
  };

  services = {
    udev.extraRules = ''
      # Epson TM-T20III (04b8:0e28) — raw USB for tm20/nusb, not CUPS.
      SUBSYSTEM=="usb", ATTR{idVendor}=="04b8", ATTR{idProduct}=="0e28", MODE="0660", GROUP="plugdev", TAG+="uaccess"

      ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_interface", ATTRS{idVendor}=="04b8", ATTRS{idProduct}=="0e28", ATTR{bInterfaceClass}=="07", RUN+="${pkgs.bash}/bin/sh -c 'echo -n $kernel > /sys/bus/usb/drivers/usblp/unbind'"
    '';
  };

  # system.nix includes this file; empty is enough for nix-daemon to start.
  environment.etc."nixos/secrets/nix-access-tokens.conf" = {
    text = "";
    mode = "0600";
  };

  environment.systemPackages = with pkgs; [
    coreutils
    curl
    usbutils
    libusb1
    liberation_ttf
    tm20-cli
  ];

  system.stateVersion = "25.11";
}
