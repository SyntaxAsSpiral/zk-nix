# NixOS configuration for tm20 — Pi 3B+ print-host appliance.
# Minimal: firmware, NM, Tailscale, SSH, Epson USB. No desktop, no HM, no core profile.
{
  pkgs,
  lib,
  config,
  modulesPath,
  ...
}:

{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    ../../modules/system.nix
    ../../modules/networking.nix
    ../../modules/ssh-identity.nix
    ./print-receiver.nix
  ];

  my.host = "tm20";

  sdImage.compressImage = false;
  # Bake tm20 host keys so first boot can decrypt wifi-password.age (GBZ).
  # Replaces the aarch64 default; keep the extlinux populate.
  sdImage.populateRootCommands = lib.mkForce ''
    mkdir -p ./files/boot
    ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    mkdir -p ./files/etc/ssh
    install -m 0600 ${../../secrets/hosts/tm20/ssh_host_ed25519_key} ./files/etc/ssh/ssh_host_ed25519_key
    install -m 0644 ${../../secrets/hosts/tm20/ssh_host_ed25519_key.pub} ./files/etc/ssh/ssh_host_ed25519_key.pub
    install -m 0600 ${../../secrets/hosts/tm20/ssh_host_rsa_key} ./files/etc/ssh/ssh_host_rsa_key
    install -m 0644 ${../../secrets/hosts/tm20/ssh_host_rsa_key.pub} ./files/etc/ssh/ssh_host_rsa_key.pub
  '';
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
    isNormalUser = true;
    uid = 1000;
    description = "zk@tm20";
    extraGroups = [
      "wheel"
      "networkmanager"
      "plugdev"
      "dialout"
    ];
    linger = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBfoVdWpimtBi0htouhMDsD1NXuKbIAusgzB1dxYDW4z"
    ];
  };
  security.sudo.wheelNeedsPassword = false;

  services.getty.autologinUser = "zk";
  services.openssh.enable = true;
  programs.mosh.enable = true;

  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
    "/home/zk/.ssh/id_ed25519"
  ];
  age.secrets.wifi-password = {
    file = ../../secrets/wifi-password.age;
    owner = "zk";
    group = "users";
    mode = "0400";
    path = "/run/secrets/wifi-password";
  };
  age.secrets.print-token = {
    file = ../../secrets/print-token.age;
    owner = "zk";
    group = "plugdev";
    mode = "0400";
    path = "/run/secrets/print-token";
  };

  # system.nix includes this file; empty is enough for nix-daemon to start.
  environment.etc."nixos/secrets/nix-access-tokens.conf" = {
    text = "";
    mode = "0600";
  };

  environment.systemPackages = with pkgs; [
    coreutils
    git
    tmux
    ripgrep
    curl
    usbutils
    libusb1
    liberation_ttf
    tm20-cli
  ];

  services.udev.extraRules = ''
    # Epson TM-T20III (04b8:0e28) — raw USB for tm20/nusb, not CUPS.
    SUBSYSTEM=="usb", ATTR{idVendor}=="04b8", ATTR{idProduct}=="0e28", MODE="0660", GROUP="plugdev", TAG+="uaccess"

    ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_interface", ATTRS{idVendor}=="04b8", ATTRS{idProduct}=="0e28", ATTR{bInterfaceClass}=="07", RUN+="${pkgs.bash}/bin/sh -c 'echo -n $kernel > /sys/bus/usb/drivers/usblp/unbind'"
  '';

  system.stateVersion = "25.11";
}
